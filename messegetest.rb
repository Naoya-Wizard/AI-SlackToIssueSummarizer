require 'net/http'
require 'uri'
require 'json'

# 環境変数からSlackのトークンを取得
SLACK_TOKEN = ENV['SLACK_API_REACTIONTRACKER_TOKEN']

def fetch_all_replies(channel_id, timestamp)
  all_messages = []

  loop do
    # Slack APIのURLとパラメータ
    uri = URI("https://slack.com/api/conversations.replies")
    params = {
      channel: channel_id,
      ts: timestamp,
      pretty: 1,
      inclusive: true
    }
    uri.query = URI.encode_www_form(params)

    # HTTPリクエストの作成
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{SLACK_TOKEN}"

    # HTTPリクエストの送信
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    # レスポンスの解析
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)

      if data['ok']
        all_messages.concat(data['messages'])
        break unless data['has_more']
        # 次のページのためのタイムスタンプを更新
        timestamp = data['messages'].last['ts']
      else
        puts "Error: #{data['error']}"
        break
      end
    else
      puts "HTTP Error: #{response.message}"
      break
    end
  end

  all_messages
end

# 使用例
channel_id = 'C063ATQ0A84'
timestamp = '1703343054.704329'

messages = fetch_all_replies(channel_id, timestamp)
all_messages_text = messages.map { |message| message['text'] }.join("\n---\n")
puts "Message text:\n#{all_messages_text}"
