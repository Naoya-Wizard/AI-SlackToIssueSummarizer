require 'sinatra'
require 'json'
require 'yaml'
require './NotionPagePoster'

# profiles フォルダ内の全ての YAML ファイルを読み込む
profile_files = Dir[File.join(File.dirname(__FILE__), 'profiles', '*.yml')]
all_profiles = profile_files.each_with_object({}) do |file_path, profiles|
  profile = YAML.load_file(file_path)
  profiles.merge!(profile) { |key, oldval, newval| oldval + newval }
end

# 読み込んだプロファイルを出力する
all_profiles['valid_reactions'].each do |reaction_profile|
  puts "User: #{reaction_profile['user']}, Reaction: #{reaction_profile['reaction']}, Notion Page ID: #{reaction_profile['notion_page_id']}"
end

post '/slack/events' do
  begin
    request_data = JSON.parse(request.body.read)
    puts request_data
    case request_data['type']
    when 'url_verification'
      # SlackのURL検証に応答
      request_data['challenge']

    when 'event_callback'
      event = request_data['event']

      if event['type'] == 'reaction_added'
        # リアクションが追加されたことを処理
        puts "リアクションが追加されました: #{event}"

        valid_reaction = config['valid_reactions'].find do |entry|
          entry['user'] == event['user'] && entry['reaction'] == event['reaction']
        end

        if valid_reaction
          notion_page_id = valid_reaction['notion_page_id']
          NotionPagePoster.post_to_notion("Your Page Title", "Your main content here.")
          return "Notion page created for reaction: #{event['reaction']}"
        end
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
