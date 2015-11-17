require 'aws-sdk-core'
require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Route53Zone < Infraset::Resource
        # credentials = Aws::SharedCredentials.new(profile_name: ‘my_profile_name’)

        attribute :domain, String, default: :name
        attribute :vpc, String
        attribute :vpc_region, String, default: ENV['AWS_DEFAULT_REGION'] || 'us-east-1'
        attribute :comment, String, default: 'Managed by Infraset'


        def execute
          if @to_be_created
            client.create_hosted_zone options
          elsif @to_be_updated
            client.update_hosted_zone_comment id: state[:id], comment: comment
          elsif @to_be_deleted
            client.delete_hosted_zone id: state[:id]
          end
        end

        def uid
          vpc ? "#{provider}:#{type}[#{name}/#{vpc}]" : super
        end

        def state
          unless @state['id']
            @state[:attributes] = {
              domain: name,
              comment: comment,
              vpc_id: vpc,
              vpc_region: vpc_region
            }
          end

          @state
        end


        private

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

          def save_state(response)
            @current_state[:id] = response.hosted_zone.id.sub('/hostedzone/', '')
            @current_state[:attributes] = {
              domain: response.hosted_zone.name.chomp('.'),
              comment: response.hosted_zone.config.comment,
              vpc_id: response.vpc.vpc_id,
              vpc_region: response.vpc.vpc_region
            }
          end

          def client
            @client ||= ::Aws::Route53::Client.new
          end

      end
    end
  end
end