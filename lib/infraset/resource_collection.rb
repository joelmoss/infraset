module Infraset
  class ResourceCollection < Array
    include Utilities

    def <<(item)
      if item.is_a?(ResourceFile)
        add_from_resource_file(item)
      elsif item.is_a?(Resource)
        super
      else
        raise ArgumentError, 'ResourceCollection only accepts a ResourceFile or Resource'
      end
    end

    def add_from_resource_file(resource_file)
      resource_file.each { |resource| self << resource }
    end

    def execute
      each do |res|
        logger.info "- #{res}"
        res.execute
      end
    end

  end
end
