require 'hashdiff'

module Infraset
  class ResourceCollection < Array
    include Utilities

    # Append a resource to the collection. This behaves just like `Array#<<`, but only accepts a
    # `Resource` or `ResourceFile`, otherwise an `ArgumentError` is raised. If a `ResourceFile` is
    # given, then each `Resource` found in that file will be appended to the collection instead.
    def <<(item)
      if item.is_a?(ResourceFile)
        add_from_resource_file item
      elsif item.is_a?(Resource)
        super
      else
        raise ArgumentError, 'ResourceCollection only accepts a ResourceFile or Resource'
      end
    end

    def current_state=(state)
      each do |resource|
        resource.current_state = state[resource.uid]
      end unless state.empty?
    end

    # Compile the resources in this collection and generate the plan. This includes validation of
    # the resources, including a check that all UID's are unique.
    def compile!
      validate_uids
      generate_plan
    end

    def execute!
      each do |resource|
        logger.info "- #{resource}"
        resource.execute!
        yield resource if block_given?
      end
    end


    private

      def add_from_resource_file(resource_file)
        resource_file.each { |resource| self << resource }
      end

      # Check that each resource UID is unique, otherwise we raise an exception.
      def validate_uids
        each do |resource|
          matching = find_all { |r| r.uid == resource.uid }
          if matching.count > 1
            raise "#{resource} is not unique, because another resource has been found with the same UID" +
                  " (#{resource.uid}).\n     " + matching.map { |r| "#{r} in #{r.path}" }.join("\n     ")
          end
        end
      end

      # Takes the current state and applies it to each resource
      def apply_current_state(state)
        each do |resource|
          resource.state[:id] = state['resources'][resource.uid]['id']
          resource.state[:attributes] = state['resources'][resource.uid]['attributes']
        end
      end

      # Generate the planned state by comparing the resources against the current state.
      def generate_plan
        plan_counts = {
          created: 0,
          modified: 0,
          removed: 0
        }

        logger.info do
          each do |r|
            if r.current_state[:id]
              # Resource already exists
              diff = HashDiff.diff(r.current_state[:attributes], r.planned_state[:attributes])

              unless diff.empty?
                plan_counts[:modified] =+ 1
                r.should_update!
                logger.modified r do
                  length = diff.sort_by { |type,name,old,new| name.length }.last[1].length
                  diff.each do |type,name,old,new|
                    name = "#{name}:".rjust(length+1)
                    logger.info "#{name} #{old.inspect} => #{new.inspect}"
                  end
                end
              end
            else
              # Resource does not yet exist
              plan_counts[:created] =+ 1
              r.should_create!
              logger.added r do
                planned_attrs = r.planned_state[:attributes]
                length = Hash[r.attributes.sort_by { |key, val| key.length }].keys.last.length
                r.attributes.each do |key,params|
                  name = "#{key}:".rjust(length+1)
                  value = planned_attrs[key] || r.send(key)
                  logger.info "#{name} #{value}"
                end
              end
            end
          end

          logger.info "\n   Plan: #{plan_counts[:created]} to add, #{plan_counts[:modified]} to change, #{plan_counts[:removed]} to destroy."
        end
      end

  end
end
