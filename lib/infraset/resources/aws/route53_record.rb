require 'aws-sdk-core'
require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Route53Record < Infraset::Resource

        attribute :zone_id, String, required: true, recreate_on_update: true, relation: 'aws:route53_zone'
        attribute :name, String, default: :name, required: true
        attribute :type, String, required: true
        attribute :records, Array, required: true
        attribute :ttl, Integer, default: 3600


        def refresh!
          sets = client.list_resource_record_sets(
            hosted_zone_id: zone_id,
            start_record_name: name,
            start_record_type: type
          )

          record = false
          sets.resource_record_sets.each do |set|
            n = clean_record_name(set.name)

            next unless fqdn(n.downcase) == fqdn(name.downcase)
            next unless set.type.upcase == type.upcase

            record = set
            self.records = set.resource_records.map(&:value)
            break
          end

          raise "#{uid}: Error setting records; cannot find `#{type} #{name}`" unless record

          self.ttl = record.ttl
          self
        end


        private

          def non_alias?
            attributes[:alias].empty?
          end

          def create!
            client.change_resource_record_sets(create_options)
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

          def create_options
            opts = {
              hosted_zone_id: zone_id,
              change_batch: {
                changes: [{
                  action: 'CREATE',
                  resource_record_set: {
                    name: name,
                    type: type,
                    ttl: 3600,
                    resource_records: records.map {|rec| {value: rec}}
                  }
                }]
              }
            }

            p opts
            opts
          end

          def save_resource_after_create(res)
            p res
            @id = res.change_info.id.sub('/change/', '')
            # self.domain = res.hosted_zone.name.chomp('.')
            # self.comment = res.hosted_zone.config.comment
            # self.vpc = (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_id) || nil
            # self.vpc_region = (res.respond_to?(:vpc) && res.vpc && res.vpc.vpc_region) || nil
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

          # Route 53 stores the "*" wildcard indicator as ASCII 42 and returns the octal equivalent,
          # "\\052". Here we look for that, and convert back to "*" as needed.
          def clean_record_name(record_name)
            if record_name.start_with?("\\052")
              record_name.gsub! "\\052", "*"
              logger.debug("Replacing octal \\052 for * in: #{record_name}")
            end

            record_name
          end

          def fqdn(record_name)
            record_name.end_with?('.') ? record_name : "#{record_name}."
          end

      end
    end
  end
end