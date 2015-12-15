require 'infraset'
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
    # 1. We scan the `resource_path` for Ruby files and collect the resources found within them, and
    #    add each resource to the `run_context.resource_collection`.
    # 2. Read the current state from the `state_file` if it exists.
    # 3. Refresh the current state found in step 2, by querying the provider of each resource and
    #    updating the current state.
    # 4. Compile the resources and build the plan of the what resources will be added, modified
    #    and/or removed. To do this, we generate the planned state and compare it against the
    #    current state.
    # 5. Execute the resource plan.
    def execute!
      setup

      # Read the current state and populate the `resources`.
      read_current_state

      # Collect any resources from the resource files, and update the `resources`.
      collect_resources

      validate_uids!
      generate_plan_for(plan_summary)

      # read_state
      # refresh_state
      # compile_resources
      # execute_resources
      # write_state

      @kernel.exit 0
    rescue => e
      logger.fatal e
      @kernel.exit 1
    end

    # Check that each resource UID is unique, otherwise raise an exception.
    def validate_uids!
      resources.each do |uid,res|
        matching = resources.find_all { |r_uid,r_res| r_uid == uid }
        if matching.count > 1
          raise "#{resource} is not unique, because another resource has been found with the same UID" +
                " (#{resource.uid}).\n     " + matching.map { |r| "#{r} in #{r.path}" }.join("\n     ")
        end
      end
    end

    def generate_plan_for(summary)
      summary.each do |action,uids|
        next if uids.count < 1

        logger.info "Will #{action} #{uids.count} resource(s)..." do
          uids.each do |uid|
            if action == :delete
              logger.deleted uid
            elsif action == :create
              r = resources[uid]

              logger.created r do
                length = Hash[r.attributes.sort_by { |key, val| key.length }].keys.last.length
                r.attributes.each do |name,attr|
                  name = "#{name}:".ljust(length+2)
                  logger.info "#{name} #{attr.value.inspect}"
                end
              end
            elsif action == :recreate
              r = resources[uid]

              logger.recreated r do
                length = Hash[r.attributes.sort_by { |key, val| key.length }].keys.last.length
                r.attributes.each do |name,attr|
                  name = "#{name}:".ljust(length+2)
                  if attr.diff
                    diff = attr.diff
                    recreate_log = nil

                    # Does modifying this attribute require that we recreate a new resource?
                    if attr.options[:recreate_on_update]
                      recreate_log = Paint['  * Forces new resource!', :red]
                    end

                    logger.info "#{name} #{diff[:old_value].inspect} => #{diff[:new_value].inspect}#{recreate_log}"
                  else
                    logger.info "#{name} #{attr.value.inspect}"
                  end
                end
              end
            elsif action == :update
              r = resources[uid]

              logger.updated r do
                length = r.diff.sort_by { |type,name,old,new| name.length }.last[1].length
                r.diff.each do |type,name,old,new|
                  recreate_log = nil

                  # Does modifying this attribute require that we recreate a new resource?
                  if r.should_recreate_for?(name)
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
        create:   [],
        recreate: [],
        update:   [],
        delete:   []
      }
      resources.each { |uid,res| plan[res.planned_action] << uid }
      plan
    end

    # Fetches and reads the current state if available in the state file. Otherwise, a new empty
    # state file is created. This state is then saved to the run context as the current state.
    def read_current_state
      logger.info "Reading current state from #{configuration.state_file}" do
        state_file = File.expand_path(configuration.state_file)
        if File.exist?(state_file)
          begin
            JSON.parse(IO.read(state_file))
          rescue => e
            raise e.class, "Unable to read/parse state file\n     #{e}"
          end.each { |uid,params| resources[uid] = params }
        else
          logger.info "State file does not exist at #{state_file}. Creating..."
          state_dir = File.dirname(state_file)
          if Dir.exist? state_dir
            File.write state_file, resources.to_json
          else
            raise "Cannot create state file in #{state_dir}. Does that directory exist?"
          end
        end
      end
    end

    # Collect the resources at the `resource_path` by scanning for Ruby files at the top level, and
    # add them to the `resources` collection.
    def collect_resources
      logger.info "Collecting resources from #{configuration.resource_path}" do
        Dir.glob(File.join(configuration.resource_path, "*.rb")).each do |file|
          resources.add_or_update ResourceFile.new(file)
        end

        resources.each do |uid,res|
          res.should_delete! unless res.found_in_files
        end
      end
    end

    # TODO!
    # Loop through each resource in the current state and refresh it. This only refreshes the state
    # of existing resources by fetching the actual resource data from the provider.
    def refresh_state
      logger.info "Refreshing current state... (TODO)" do
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
      end if configuration.execute
    end

    # Write the state back to the state file from the run context.
    def write_state
      logger.info "Writing state to #{configuration.state_file}" do
        run_context.write_state!
      end if configuration.execute
    end


    private

      def setup
        puts banner if $stdout.tty?
        parse_options @argv
        configuration.merge! config
        @resources = Resources.new
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
