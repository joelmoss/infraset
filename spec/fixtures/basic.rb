resource :aws, :route53_zone, 'joelmoss.com' do
  vpc 'vpc-2f2f904b'
  comment 'new commentw'
end

resource :aws, :route53_zone, 'joelmoss2.com'
resource :aws, :route53_zone, 'joelmoss3.com'

# resource :aws, :route53_zone, 'joelmoss.com' do
#   comment 'blah'
# end
resource :aws, :route53_zone, 'joelmoss.com'

# resource :aws, :animal, 'milo' do
#   species 'dog'
# end
