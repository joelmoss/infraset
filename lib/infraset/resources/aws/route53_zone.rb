require 'aws-sdk-core'
require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Route53Zone < Infraset::Resource
        # credentials = Aws::SharedCredentials.new(profile_name: ‘my_profile_name’)

        attribute :domain, String,
                  default: :name,
                  recreate_on_update: true
        attribute :vpc, String,
                  recreate_on_update: true
        attribute :vpc_region, String,
                  recreate_on_update: true,
                  required_if: :vpc_given?
        attribute :comment, String,
                  default: 'Managed by Infraset'


        def uid
          vpc ? "#{@provider}:#{@type}[#{name}/#{vpc}]" : super
        end

        def refresh!
          zone = client.get_hosted_zone(id: id)

          self.comment = zone.hosted_zone.config.comment
          if zone.vp_cs.empty?
            self.vpc = nil
            self.vpc_region = nil
          else
            self.vpc = zone.vp_cs[0].vpc_id
            self.vpc_region = zone.vp_cs[0].vpc_region
          end

          self
        end


        private

          def vpc_given?
            !attributes[:vpc].blank?
          end

          def create!
            options = {
              name: name,
              hosted_zone_config: {
                comment: comment
              },
              caller_reference: SecureRandom.uuid
            }

            options[:vpc] = {
              vpc_id: vpc,
              vpc_region: vpc_region
            } if vpc

            client.create_hosted_zone options
          end

          def recreate!
            delete! && create!
          end

          def delete!
            client.delete_hosted_zone id: id
          end

          def update!
            client.update_hosted_zone_comment id: id, comment: comment
          end

          def save_resource_after_create(res)
            @id = res.hosted_zone.id.sub('/hostedzone/', '')
            self.domain = res.hosted_zone.name.chomp('.')
            self.comment = res.hosted_zone.config.comment
            self.vpc = (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_id) || nil
            self.vpc_region = (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_region) || nil
          end

          def save_resource_after_recreate(res)
            save_resource_after_create res
          end

          def save_resource_after_update(res)
            self.comment = res.hosted_zone.config.comment
          end

          def client
            @client ||= ::Aws::Route53::Client.new
          end

      end
    end
  end
end