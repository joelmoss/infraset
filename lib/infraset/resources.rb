require 'infraset/resource'

module Infraset
  class Resources < ActiveSupport::HashWithIndifferentAccess
    include Infraset::Utilities

    def []=(uid, params)
      if params.is_a?(Resource)
        super uid, params
      else
        params = params.with_indifferent_access
        resource_class = require_resource(params[:provider][:name], params[:provider][:type])
        super uid, resource_class.new(params[:name], params[:provider], params[:attributes])
      end
    end

    # Take a file or resource and add it to the resource collection. If the resource already exists
    # in the collection, the existing resource will be updated.
    def add_or_update(file_or_resource)
      if file_or_resource.is_a?(ResourceFile)
        file_or_resource.each do |res|
          if self[res.uid]
            # p 'current:'
            # self[res.uid].print_attributes

            # Compare current resource against the new.
            unless (diff = self[res.uid].diff_against(res)).empty?
              self[res.uid].diff = diff
              to_recreate = false

              diff.each do |type,name,old,new|
                self[res.uid].attributes[name].diff = {
                  type: type,
                  old_value: old,
                  new_value: new
                }

                # Does modifying this resource require that we recreate the resource?
                if !to_recreate && self[res.uid].should_recreate_for?(name)
                  to_recreate = true
                  self[res.uid].should_recreate!(res)
                end
              end

              self[res.uid].should_update!(res) unless to_recreate
            end
          else
            self[res.uid] = res.should_create!
          end

          self[res.uid].found_in_files = true

          # p 'plan:'
          # res.print_attributes
        end
      elsif file_or_resource.is_a?(Resource)

      else
        raise ArgumentError, 'Resources#add_or_update only accepts a ResourceFile or Resource'
      end
    end

  end
end
