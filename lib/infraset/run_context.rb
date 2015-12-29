require 'infraset/resources'
require 'infraset/state'

module Infraset
  class RunContext
    include Infraset::Utilities

    attr_accessor :resources, :state

    def initialize
      @state, @resources, @executed = State.new, Resources.new, []
    end

    # Validate the given `resource` and add it to the current state.
    def add_state(uid, resource)
      state.validate_uid_of! resource
      state[uid] = resource
    end

    # Validate each resource found in the given resource `file` and add to the resources.
    def add_resource_from_file(file)
      file.each do |resource|
        resources.validate_uid_of! resource
        resources[resource.uid] = resource
      end
    end

    # Merges the state into the resources.
    def merge_resources
      resources.each do |uid,resource|
        next unless (existing = state[uid])
        resource.id = existing.id
      end
    end

    def refresh_state
      state.each do |uid,resource|
        state[uid] = resource.refresh!
      end

      write_state!
    end

    def empty_plan?
      plan[:create].empty? && plan[:recreate].empty? && plan[:update].empty? && plan[:delete].empty?
    end

    def plan
      @plan ||= {
        create: {},
        recreate: {},
        update: {},
        delete: {}
      }.with_indifferent_access
    end

    def build_plan
      plan_changes
      plan_deleted
    end

    def print_plan
      plan.each do |action,uids|
        next if uids.count < 1

        logger.info "Will #{action} #{uids.count} resource(s)..." do
          uids.each do |uid,diff|
            case action
            when 'delete'
              logger.deleted uid
            when 'create'
              logger.created (r = resources[uid]) do
                length = longest_attr_by_name(r.attributes)
                r.attributes.each do |name,attr|
                  name = "#{name}:".rjust(length+2)
                  logger.info "#{name} #{attr.value.inspect}"
                end
              end
            when 'recreate'
              logger.recreated (r = resources[uid]) do
                length = longest_attr_by_name(r.attributes)

                recreate_log = nil
                diff.each do |type,name,old,new|
                  if r.should_recreate_for?(name)
                    recreate_log = Paint['  * Forces new resource!', :red]
                  end

                  name = "#{name}:".rjust(length+2)
                  logger.info "#{name} #{old.inspect} => #{new.inspect}#{recreate_log}"
                end
              end
            when 'update'
              logger.updated (r = resources[uid]) do
                length = diff.sort_by { |type,name,old,new| name.length }.last[1].length
                diff.each do |type,name,old,new|
                  name = "#{name}:".rjust(length+2)
                  logger.info "#{name} #{old.inspect} => #{new.inspect}"
                end
              end
            end
          end
        end
      end

      logger.info "\n   Plan: #{plan[:create].count} to create, " +
                  "#{plan[:recreate].count} to recreate, " +
                  "#{plan[:update].count} to update, " +
                  "#{plan[:delete].count} to destroy.\n\n"
    end

    def execute!
      plan.each do |action,uids|
        next if uids.count < 1

        uids.each do |uid,diff|
          if (res = resources[uid])
            logger.info "Executing '#{action}' on #{uid}"
            res.execute!(action)
            state[uid] = res
          else
            if action == 'delete'
              logger.info "Executing '#{action}' on #{uid}"
              state[uid].execute!(action)
              state.delete uid
            end
          end
        end
      end
    end

    def write_state!
      state_file = File.expand_path(configuration.state_file)
      File.write state_file, state.to_json
    end


    private

      # Find new and updated resources. If the resource already exists in the current state, the
      # existing resource will be updated or recreated. Otherwise it will be created.
      def plan_changes
        resources.each do |uid,res|
          if state[uid] # resource exists
            existing_resource = state[uid]

            # Compare current resource against the new.
            unless (diff = existing_resource.diff_against(res)).empty?
              should_recreate = false
              diff.each do |type,name,old,new|
                # Does modifying this resource require that we recreate the it?
                if existing_resource.should_recreate_for?(name)
                  should_recreate = true
                  break
                end
              end

              if should_recreate
                plan[:recreate][uid] = diff
              else
                plan[:update][uid] = diff
              end
            end
          else # resource does not exist
            plan[:create][uid] = []
          end
        end
      end

      # Find deleted resources - resources that exist in state only.
      def plan_deleted
        state.each do |uid,res|
          plan[:delete][uid] = [] unless resources[uid]
        end
      end

      def longest_attr_by_name(attributes)
        Hash[attributes.sort_by { |key, val| key.length }].keys.last.length
      end

  end
end