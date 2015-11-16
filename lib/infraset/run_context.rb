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
      resource_collection.compile!
    end

    def execute!
      if config.execute
        resource_collection.execute! { |resource| save_state resource }
      else
        logger.warn "Execution of #{resource_collection.count} resource(s) will " +
                    "not occur due to `--no-execute` having been given."
      end
    end

    def save_state(resource)
      logger.debug "Saving state for #{resource}"
      current_state[:resources][resource.uid] = resource.current_state
    end

    def write_state!
      state_file = File.expand_path(config.state_file)
      File.write state_file, JSON.generate(current_state)
    end

  end
end