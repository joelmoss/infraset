require 'forwardable'

require 'infraset/resources'

module Infraset
  class RunContext
    include Infraset::Utilities
    extend Forwardable

    attr_accessor :resources
    def_delegator :@resources, :each
    def_delegator :@resources, :count


    def initialize
      @resources = Resources.new
    end

    def add_resource(uid, data)
      @resources[uid]
    end

    # Fetches and reads the current state if available in the state file. Otherwise, a new empty
    # state file is created.
    def read_state
      state_file = File.expand_path(configuration.state_file)
      if File.exist?(state_file)
        begin
          JSON.parse(IO.read(state_file))
        rescue => e
          raise e.class, "Unable to read/parse state file\n     #{e}"
        end.each { |uid,data| add_resource uid, data }
      else
        logger.warn "State file does not exist at #{state_file}. Creating..."
        state_dir = File.dirname(state_file)
        if Dir.exist? state_dir
          File.write state_file, {}.to_json
        else
          raise "Cannot create state file in #{state_dir}. Does that directory exist?"
        end
      end
    end

    def refresh!
      resources.refresh!
      write_state!
    end

    def collect
      Dir.glob(File.join(configuration.resource_path, "*.rb")).each do |file|
        ResourceFile.new(file).each do |resource|
          # resources.validate_uid_of! resource
          resources[resource.uid] = resource
        end
      end
    end


    private

      def write_state!
        File.write File.expand_path(configuration.state_file), resources.to_json
      end

  end
end
