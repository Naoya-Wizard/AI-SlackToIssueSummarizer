require 'net/http'
require 'json'
require 'uri'

module NotionPagePoster
  def self.post_to_notion(title, content)
    token = ENV['NOTION-INTEGRATION-TOKEN']
    page_id = 'e0f0b5be359f4912a3c6855fe54f0e6d'
    headers = {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json",
      "Notion-Version" => "2021-05-13"
    }

    data = {
      "parent" => {"page_id" => page_id},
      "properties" => {
        "title" => {
          "title" => [
            {
              "text" => {
                "content" => title
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
                  "content" => content
                }
              }
            ]
          }
        }
      ]
    }.to_json

    uri = URI.parse('https://api.notion.com/v1/pages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = data

    response = http.request(request)
    puts response.body
  end
end
