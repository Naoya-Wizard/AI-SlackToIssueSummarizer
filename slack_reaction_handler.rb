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
  request_data = JSON.parse(request.body.read)

  case request_data['type']
  when 'url_verification'
    request_data['challenge']

  when 'event_callback'
    event = request_data['event']

    if event['type'] == 'reaction_added'
      puts "リアクションが追加されました: #{event}"

      valid_reaction = all_profiles['valid_reactions'].find do |entry|
        entry['user'] == event['user'] && entry['reaction'] == event['reaction']
      end

      if valid_reaction
        # ここでSlack APIを呼び出す
        if event['item'] && event['item']['type'] == 'message'
          channel_id = event['item']['channel']
          timestamp = event['item']['ts']
          messages = Slack_message_fetcher.fetch_all_replies(channel_id, timestamp)
          puts messages.map { |message| message['text'] }.join("\n---\n")
        end

        notion_page_id = valid_reaction['notion_page_id']
        NotionPagePoster.post_to_notion(notion_page_id, "Your Page Title", messages)
        return "Notion page created for reaction: #{event['reaction']}"
      end
    end

    status 200
  else
    status 400
    "Unknown event type"
  end
rescue JSON::ParserError
  status 400
  "Invalid JSON format"
end
