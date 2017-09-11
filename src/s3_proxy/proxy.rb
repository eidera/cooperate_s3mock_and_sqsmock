require 'uri'
require 'kage'

Kage::ProxyServer.start do |server|
  server.port = 9001
  server.host = '0.0.0.0'
  server.debug = false

  server.add_master_backend(:s3, 's3_mock', 9000) # S3モック
  server.add_backend(:sqs, 'sqs_sender', 9030) # SQSモック
end
