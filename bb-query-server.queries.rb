require 'aquae/protos/messaging.pb'
question 'bb?' do |answers|
  (answers['pip>8?'].is_a? Aquae::Messaging::ValueResponse) || (answers['dla-higher?'].is_a? Aquae::Messaging::ValueResponse)
end