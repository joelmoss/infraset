resource :aws, :route53_zone, 'joelmoss.com' do
  comment 'blah!'
  vpc 'vpc-2f2f904b'
end

# resource :aws, :animal, 'milo' do
#   species 'dog'
# end
