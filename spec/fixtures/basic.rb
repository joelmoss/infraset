resource :aws, :route53_zone, 'joelmoss.com' do
  comment 'some comment'
  vpc 'vpc-2f2f904b'
  vpc_region 'us-east-1'
end

resource :aws, :route53_record, 'www.joelmoss.com' do
  zone_id refs('aws:route53_zone[joelmoss.com/vpc-2f2f904b]').id
  # zone_id 'Z2WOHHFBGAQ97L'
  type 'A'
  records ['192.0.2.1']
end

# resource :aws, :route53_zone, 'joelmoss.com' do
#   vpc 'vpc-2f2f904b'
#   vpc_region 'us-east-1'
#   comment 'new commentss'
# end

# resource :aws, :route53_zone, 'joelmoss3.com'

# resource :aws, :route53_zone, 'joelmoss.com' do
#   comment 'adsf'
# end

# resource :aws, :animal, 'milo' do
#   species 'dog'
# end
