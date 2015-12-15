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
                  default: 'Managed by Infraset', recreate_on_update: true


        def execute
          if @to_be_created
            create!
          elsif @to_be_updated
            @to_be_recreated ? recreate! : update!
          elsif @to_be_deleted
            delete!
          end
        end

        def uid
          vpc ? "#{provider}:#{type}[#{name}/#{vpc}]" : super
        end


        private

          def vpc_given?
            vpc
          end

          def create!
            client.create_hosted_zone options
          end

          def recreate!
            delete! && create!
          end

          def delete!
            client.delete_hosted_zone id: current_state[:id]
          end

          def update!
            client.update_hosted_zone_comment id: current_state[:id], comment: comment
          end

          def options
            opts = {
              name: name,
              hosted_zone_config: {
                comment: comment
              },
              caller_reference: SecureRandom.uuid
            }

            opts[:vpc] = {
              vpc_id: vpc,
              vpc_region: vpc_region
            } if vpc

            opts
          end

          def save_state_after_creation(res)
            current_state[:id] = res.hosted_zone.id.sub('/hostedzone/', '')
            current_state[:attributes] = {
              domain: res.hosted_zone.name.chomp('.'),
              comment: res.hosted_zone.config.comment,
              vpc: (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_id) || nil,
              vpc_region: (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_region) || nil
            }
          end

          def save_state_after_recreation(res)
            save_state_after_creation res
          end

          def save_state_after_update(res)
            current_state[:attributes][:comment] = res.hosted_zone.config.comment
          end

          def save_state_after_deletion(res)
            p res
            p '?'
          end

          def client
            @client ||= ::Aws::Route53::Client.new
          end

      end
    end
  end
end