resource :aws, :route53_zone, 'joelmoss.com' do
  vpc 'vpc-2f2f904b'
  comment 'new comment'
end

# resource :aws, :route53_zone, 'joelmoss.com'
# resource :aws, :route53_zone, 'joelmoss2.com'

# resource :aws, :animal, 'milo' do
#   species 'dog'
# end
