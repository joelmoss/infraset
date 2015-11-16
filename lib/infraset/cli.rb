require 'infraset'
require 'infraset/run_context'
require 'infraset/resource_file'
require 'infraset/resource_collection'

module Infraset
  class CLI
    include Mixlib::CLI
    include Utilities

    attr_accessor :run_context

    option :resource_path,
      short: '-r PATH',
      long: '--resource-path PATH',
      description: 'The relative path where the resources reside'

    option :state_file,
      short: '-s PATH',
      long: '--state-file FILE',
      description: 'The relative path to the state file'

    option :execute,
      long: '--[no-]execute',
      boolean: true,
      default: true,
      description: 'Execute the plan'

    option :debug,
      short: '-d',
      long: '--[no-]debug',
      boolean: true,
      default: false,
      description: 'Set the log level to debug'


    # The main execution method that is called when the CLI is run. Exits with a non-zero exit code
    # if unsuccessful. If the `execution` option is false, then any resource plan will not be
    # executed.
    def run
      setup

      collect_resources
      read_state
      refresh_state
      compile_resources
      execute_resources
      write_state

      exit 0
    rescue => e
      logger.fatal e
    end

    # Collect the resources at the `resource_path` by scanning for Ruby files at the top level, and
    # add them to the `resource_collection` of the `run_context`.
    def collect_resources
      logger.info "Collecting resources from #{config.resource_path}" do

        Dir.glob(File.join(config.resource_path, "*.rb")).each do |file|
          run_context.resource_collection << ResourceFile.new(file)
        end
      end
    end

    # Fetches and reads the current state if available in the state file. Otherwise, a new empty
    # state file is created. This read state is then saved to the run context as the current state.
    def read_state
      logger.info "Reading current state from #{config.state_file}" do
        state_file = File.expand_path(config.state_file)
        if File.exist?(state_file)
          begin
            run_context.current_state = JSON.parse(IO.read(state_file))
          rescue => e
            raise e.class, "Unable to read/parse state file\n     #{e}"
          end
        else
          logger.info "State file does not exist at #{state_file}. Creating..."
          state_dir = File.dirname(state_file)
          if Dir.exist? state_dir
            File.write state_file, JSON.generate(run_context.current_state)
          else
            raise "Cannot create state file in #{state_dir}. Does that directory exist?"
          end
        end
      end
    end

    # TODO!
    # Loop through each resource in the current state and refresh it. This only refreshes the state
    # of existing resources by fetching the actual resource data from the provider.
    def refresh_state
      logger.info "Refreshing current state..." do
        logger.warn 'TODO!'
      end
    end

    # Compile the resources found in the `resource_collection` of the `run_context`.
    def compile_resources
      logger.info "Compiling #{run_context.resource_collection.count} resource(s)" do
        run_context.compile!
      end
    end

    # Execute the planned resources. These will be the resources that are new, modified, or
    # destroyed as compared to the current state.
    def execute_resources
      logger.info "Executing #{run_context.resource_collection.count} resource(s)" do
        run_context.execute!
      end
    end

    # Write the state back to the state file from the run context.
    def write_state
      logger.info "Writing state to #{config.state_file}" do
        run_context.write_state!
      end
    end


    private

      def setup
        puts "\n" + Paint[banner, :green] if $stdout.tty?
        parse_options
        config.merge! config
        @run_context = RunContext.new
      end

      def banner
%Q{   _        __                    _
  (_)_ __  / _|_ __ __ _ ___  ___| |_
  | | '_ \\| |_| '__/ _` / __|/ _ \\ __|
  | | | | |  _| | | (_| \\__ \\  __/ |_
  |_|_| |_|_| |_|  \\__,_|___/\___|\\__|   #{user_agent}
}
      end

  end
end
