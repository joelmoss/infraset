module Infraset
  class ResourceCollection < Array
    include Utilities

    def <<(item)
      if item.is_a?(ResourceFile)
        add_from_resource_file item
      elsif item.is_a?(Resource)
        super
      else
        raise ArgumentError, 'ResourceCollection only accepts a ResourceFile or Resource'
      end
    end

    def add_from_resource_file(resource_file)
      resource_file.each { |resource| self << resource }
    end

    def compile
      validate_uids
      generate_state
    end

    def execute!
      each do |res|
        logger.info "- #{res}"
        res.execute
      end
    end


    private

      # Check that each resource UID is unique, otherwise we raise an exception.
      def validate_uids
        each do |res|
          matching = find_all { |r| r.uid == res.uid }
          if matching.count > 1
            raise "#{res} is not unique, because another resource has been found with the same UID" +
                  " (#{res.uid}).\n     " + matching.map { |r| "#{r} in #{r.path}" }.join("\n     ")
          end
        end
      end

      def generate_state

      end

  end
end
