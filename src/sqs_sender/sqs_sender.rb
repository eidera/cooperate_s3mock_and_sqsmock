require 'webrick'
require 'aws-sdk'

AWS_CONFIG = {
    access_key_id: 'TEST',
    secret_access_key: 'TEST',
    region: 'TEST',
    endpoint: 'http://sqs_mock:9324/'
}

# HTTPメソッドと、S3イベントとの対応
HTTP_TO_EVENTS = {
  'POST' => 'ObjectCreated:Put',
  'PUT' => 'ObjectCreated:Post',
  'DELETE' => 'ObjectRemoved:Delete'
}

# キュー名
QUEUE_NAME = 'queue1'

def send_message(method, bucket_name, path)
  event = HTTP_TO_EVENTS[method]
  return if event.nil?

  queue_url = sprintf("http://sqs_mock:9324/queue/%s", QUEUE_NAME)
  message = sprintf('{"Message": "{\"Records\":[{\"eventName\":\"%s\",\"s3\":{\"object\":{\"key\":\"%s\"},\"bucket\":{\"name\":\"%s\"}}}]}"}', event, path, bucket_name)

  sqs = Aws::SQS::Client.new(AWS_CONFIG)
  sqs.send_message(queue_url: queue_url, message_body: message)
  message
end

def process_request(req)
  # request_lineの中身は以下のような感じ
  #   PUT /bucket-name/filename.txt HTTP/1.1

  requests = req.request_line.split(' ')

  method = requests[0]
  path = requests[1]

  dirs = path.split('/')
  bucket_name = dirs[1]
  path = dirs[2..-1].join('/') # バケット名は削除

  send_message(method, bucket_name, path)
end

module WEBrick
  module HTTPServlet
    class ProcHandler < AbstractServlet
      alias do_PUT    do_GET
      alias do_DELETE do_GET
    end
  end
end

srv = WEBrick::HTTPServer.new({
  DocumentRoot:   './',
  BindAddress:    '0.0.0.0',
  Port:           '9030',
})

srv.mount_proc '/' do |req, res|
  res.body = process_request(req)
end

srv.start
