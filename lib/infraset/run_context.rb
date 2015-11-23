module Infraset
  class RunContext
    include Infraset::Utilities

    attr_accessor :resource_collection
    attr_accessor :planned_state
    attr_reader   :current_state


    def initialize
      @resource_collection = ResourceCollection.new
      @current_state = {resources:{}}.with_indifferent_access
    end

    # Set the current state  on the instance variables of the same name, and also apply each
    # resource's state on it's corresponding resource object.
    def current_state=(state)
      @current_state = state.with_indifferent_access
      resource_collection.current_state = current_state[:resources]
    end

    # Compile the resources found in the `resource_collection` by comparing with the current state.
    # This will determine what resources should be added, removed and/or modified.
    #
    # Resources are global, and therefore require a way to uniquely identify them across the state
    # file and resource files. While some resources unique identifier (UID) can be automatically
    # determined, some cannot. In this case, a unique name is required, otherwise a warning will be
    # shown if the UID cannot be determined.
    #
    # For example, the following resource's UID can be automatically determined because the
    # combination of the domain and VPC must be unique on AWS, so the UID will be the domain and VPC
    # ID concatenated as `mydomain.com/vpc-1234`.
    #
    #   resource :aws, :route53_zone, 'mydomain.com' do
    #     vpc 'vpc-1234'
    #   end
    #
    # The following resource's UID will be `mydomain.com`:
    #
    #   resource :aws, :route53_zone, 'mydomain.com'
    #
    # While the above will successfully compile, if you add another identical resource, it will fail
    # with a duplication warning. To resolve this, simply give the resource a unique name:
    #
    #   resource :aws, :route53_zone, 'primary mydomain.com' do
    #     domain 'mydomain.com'
    #   end
    #
    # The above will have a UID of `primary mydomain.com`.
    def compile!
      resource_collection.validate_uids!
      resource_collection.validate!
      generate_plan_for plan_summary
    end

    def execute!
      resource_collection.execute! { |resource| save_state resource }
    end

    def save_state(resource)
      logger.debug "Saving state for #{resource}"
      current_state[:resources][resource.uid] = resource.current_state
    end

    def write_state!
      state_file = File.expand_path(config.state_file)
      File.write state_file, JSON.generate(current_state)
    end


    private

      def generate_plan_for(summary)
        summary.each do |action,uids|
          next if uids.count < 1

          logger.info "Will #{action} #{uids.count} resource(s)..." do
            uids.each do |uid|
              if action == :delete
                r = current_state[:resources].find { |state_uid,attrs| uid == state_uid }
                # r.should_delete!
                logger.removed uid
              elsif action == :create
                r = resource_collection.find { |r| r.uid == uid }
                r.should_create!

                logger.added r do
                  length = Hash[r.attributes.sort_by { |key, val| key.length }].keys.last.length
                  r.attributes.each do |key,params|
                    name = "#{key}:".ljust(length+2)
                    value = r.planned_attributes[key] || r.send(key)
                    logger.info "#{name} #{value.inspect}"
                  end
                end
              elsif action == :update
                r = resource_collection.find { |r| r.uid == uid }
                r.should_update!

                logger.modified r do
                  length = r.diff.sort_by { |type,name,old,new| name.length }.last[1].length
                  r.diff.each do |type,name,old,new|
                    recreate_log = nil

                    # Does modifying this attribute require that we recreate a new resource?
                    if r.should_recreate_for?(name)
                      r.should_recreate!
                      recreate_log = Paint['  *Forces new resource!', :red]
                    end

                    name = "#{name}:".ljust(length+2)
                    logger.info "#{name} #{old.inspect} => #{new.inspect}#{recreate_log}"
                  end
                end
              end
            end
          end
        end

        logger.info "\n   Plan: #{summary[:create].count} to create, #{summary[:update].count} to " +
                    "update, #{summary[:delete].count} to destroy.\n\n"
      end

      def plan_summary
        plan = {
          create: [],
          update: [],
          delete: []
        }

        # First we loop through the current state to find updated and deleted resources
        current_state[:resources].each do |uid,attrs|
          if resource = resource_collection.find { |r| r.uid == uid } # resource is defined
            # Resource has been modified
            plan[:update] << uid unless resource.diff.empty?
          else
            # Resource is not defined, so it must have been deleted
            plan[:delete] << uid
          end
        end

        # Now loop through the defined resources (resource_collection) to find new resources
        resource_collection.each do |resource|
          unless current_state[:resources].find { |uid,attrs| uid == resource.uid }
            plan[:create] << resource.uid
          end
        end

        plan
      end

  end
end