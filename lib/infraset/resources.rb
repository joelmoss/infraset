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
    def validate!(resource)
      matching = find_all { |uid,res| uid == resource.uid }
      if matching.count > 0
        raise "Resource `#{resource}' is not unique, because another resource has\n     " +
              "been found with the same UID in " + matching.first.last.path
      end
    end

  end
end
