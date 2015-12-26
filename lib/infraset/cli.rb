require 'infraset'
require 'infraset/run_context'
require 'infraset/resources'
require 'infraset/resource_file'
require 'infraset/resource_collection'

module Infraset
  class CLI
    include Mixlib::CLI
    include Utilities

    attr_accessor :resources

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


    def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
      @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
      $stdout, $stderr = @stdout, @stderr
      super(*{})
    end

    # The main execution method that is called when the CLI is run. Exits with a non-zero exit code
    # if unsuccessful. If the `execution` option is false, then any resource plan will not be
    # executed.
    #
    # 1. Read the state file (if present), and populate the `state`.
    # 2. Scan the `resource_path` for Ruby files and collect the resources found within them, and
    #    add populate the `resources`.
    # 3. Compare the state from step 1, with the resources from step 2, which will produce and
    #    output an execution plan of changed resources.
    # 4. Execute the plan.
    # 5. Save the successful plan as the current state.
    #
    def execute!
      setup

      # Read the current state.
      read_state

      # Refresh the state.
      refresh_state

      # Collect any resources from the resource files, and validate them.
      collect_resources

      # Merge the state with the resources.
      merge_resources

      # Build and print the plan.
      build_and_print_plan

      # Execute and save the changed state.
      if !@run_context.empty_plan? && configuration.execute
        logger.ask "Do you wish to execute this plan? [y/n]\n"
        if $stdin.getch == 'y'
          execute_resources
          write_state
        end
      end

      @kernel.exit 0
    rescue => e
      logger.fatal e
      @kernel.exit 1
    end

    # Fetches and reads the current state if available in the state file. Otherwise, a new empty
    # state file is created. This state is then saved as a collection of the current resources.
    def read_state
      logger.info "Reading current state from #{configuration.state_file}" do
        state_file = File.expand_path(configuration.state_file)
        if File.exist?(state_file)
          begin
            JSON.parse(IO.read(state_file))
          rescue => e
            raise e.class, "Unable to read/parse state file\n     #{e}"
          end.each { |uid,params| @run_context.add_state uid, params }
        else
          logger.info "State file does not exist at #{state_file}. Creating..."
          state_dir = File.dirname(state_file)
          if Dir.exist? state_dir
            File.write state_file, {}.to_json
          else
            raise "Cannot create state file in #{state_dir}. Does that directory exist?"
          end
        end

        logger.debug "Found #{@run_context.state.count} resource(s) in state:"
        @run_context.state.each { |uid,res| logger.debug "  #{uid}" }
      end
    end

    # Collect the resources at the `resource_path` by scanning for Ruby files at the top level, and
    # add them to the `resources` collection.
    def collect_resources
      logger.info "Collecting resources from #{configuration.resource_path}" do
        Dir.glob(File.join(configuration.resource_path, "*.rb")).each do |file|
          @run_context.add_resource_from_file ResourceFile.new(file)
        end
      end
    end

    def build_and_print_plan
      logger.info "Building the execution plan" do
        @run_context.build_plan

        count = 0
        @run_context.plan.each { |action,data| count += data.count }
        logger.debug "Found #{count} resources in execution plan"
      end

      @run_context.print_plan
    end

    # Loop through each resource in the current state and refresh it. This only refreshes the state
    # of existing resources by fetching the actual resource data from the provider.
    def refresh_state
      logger.info "Refreshing current state..." do
        @run_context.refresh_state
      end
    end

    def merge_resources
      logger.info "Merging resources..." do
        @run_context.merge_resources
      end
    end

    # Execute the planned resources. These will be the resources that are new, modified, or
    # destroyed as compared to the current state.
    def execute_resources
      logger.info "Executing plan" do
        @run_context.execute!
      end
    end

    # Write the state back to the state file from the run context.
    def write_state
      logger.info "Writing state back to #{configuration.state_file}" do
        @run_context.write_state!
      end
    end


    private

      def setup
        puts banner if $stdout.tty?
        parse_options @argv
        configuration.merge! config
        @run_context = RunContext.new
      end

      def banner
%Q{\n   _        __                    _
  (_)_ __  / _|_ __ __ _ ___  ___| |_
  | | '_ \\| |_| '__/ _` / __|/ _ \\ __|
  | | | | |  _| | | (_| \\__ \\  __/ |_
  |_|_| |_|_| |_|  \\__,_|___/\___|\\__|   #{user_agent}
\n}
      end

  end
end
