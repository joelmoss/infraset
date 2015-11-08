require 'aws-sdk-core'
require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Route53Zone < Infraset::Resource
        # credentials = Aws::SharedCredentials.new(profile_name: ‘my_profile_name’)

        attribute :vpc, String
        attribute :vpc_region, String, default: ENV['AWS_REGION']
        attribute :comment, String, default: 'Managed by Infraset'


        def execute
          result = client.create_hosted_zone options
          logger.debug result
        rescue ::Aws::Route53::Errors::ServiceError => e
          logger.fatal e
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

            logger.debug opts
            opts
          end

          def client
            @client ||= ::Aws::Route53::Client.new
          end

      end
    end
  end
end