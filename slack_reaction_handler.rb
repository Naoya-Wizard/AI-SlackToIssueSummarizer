require 'sinatra'
require 'json'

post '/slack/events' do
  begin
    request_data = JSON.parse(request.body.read)

    case request_data['type']
    when 'url_verification'
      # SlackのURL検証に応答
      request_data['challenge']

    when 'event_callback'
      event = request_data['event']

      if event['type'] == 'reaction_added'
        # リアクションが追加されたことを処理
        puts "リアクションが追加されました: #{event}"

        # 応答の内容をここに設定できます（必要に応じて）
        "Reaction added: #{event['reaction']}"
      else
        # その他のイベントタイプについての処理（必要に応じて）
      end

      status 200
    else
      # 未知のイベントタイプについての処理
      status 400
      "Unknown event type"
    end
  rescue JSON::ParserError
    # 無効なJSONデータを受け取った場合のエラー処理
    status 400
    "Invalid JSON format"
  end
end
