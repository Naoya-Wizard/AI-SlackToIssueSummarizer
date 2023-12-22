require 'net/http'
require 'json'
require 'uri'

# トークンとページIDを設定
token = ENV['NOTION-INTEGRATION-TOKEN']
page_id = 'e0f0b5be359f4912a3c6855fe54f0e6d'

# ヘッダーに認証情報を設定
headers = {
  "Authorization" => "Bearer #{token}",
  "Content-Type" => "application/json",
  "Notion-Version" => "2021-05-13"
}

# 投稿したい本文をJSON形式で定義
data = {
  "parent" => {"page_id" => page_id},
  "properties" => {
    "title" => {
      "title" => [
        {
          "text" => {
            "content" => "Your Page Title"
          }
        }
      ]
    }
  },
  "children" => [
    {
      "object" => "block",
      "type" => "paragraph",
      "paragraph" => {
        "text" => [
          {
            "type" => "text",
            "text" => {
              "content" => "Your main content here."
            }
          }
        ]
      }
    }
  ]
}.to_json

# APIリクエストを送信
uri = URI.parse('https://api.notion.com/v1/pages')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri, headers)
request.body = data

# レスポンスを取得
response = http.request(request)

# レスポンスを表示
puts response.body
