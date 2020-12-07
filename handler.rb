# lambda_function.rb
require 'json'
require 'logger'
require 'aws-sdk-lambda'
require 'httparty'

CHUNK_SIZE=4096   # max allowed for telegram

def word_wrap(text, line_width: 80, break_sequence: "\n")
  text.split("\n").collect! do |line|
    line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1#{break_sequence}").strip : line
  end * break_sequence
end

def handle(event:, context:)
  logger = Logger.new($stdout)
  logger.info "#### EVENT ####"
  logger.info event.to_json
  
  uri = "https://api.telegram.org/bot#{ENV['TOKEN']}/sendMessage"
  chunks = word_wrap(event["body"], line_width: CHUNK_SIZE, break_sequence: "\r\r\n").split("\r\r\n")
  
  chunks.collect do |c|
    data = {
      chat_id: ENV['CHAT_ID'],
      text: c,
      disable_web_page_preview: "True"
    }

    HTTParty.post(uri, body: data)
  end
  { statusCode: 200, body: JSON.generate(chunks) }
end

def authorize(event:, context:)
  allowed = event["authorizationToken"] == ENV['AUTH_SECRET']
  {
    "principalId": "calculon",
    "policyDocument": {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "execute-api:Invoke",
          "Effect": allowed ? "Allow" : "Deny",
          "Resource": event["methodArn"]
        }
      ]
    }
  }
end
