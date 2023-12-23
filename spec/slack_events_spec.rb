require 'spec_helper'
require 'rack/test'
require_relative '../slack_reaction_handler.rb'

describe 'Slack Events API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    # Notion APIの呼び出しをモック
    allow(NotionPagePoster).to receive(:post_to_notion)
  end

  context 'POST /slack/events' do
    let(:url_verification_body) do
      {
        type: 'url_verification',
        challenge: 'test_challenge'
      }.to_json
    end

    it 'responds to URL verification challenge' do
      post '/slack/events', url_verification_body, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response).to be_ok
      expect(last_response.body).to eq('test_challenge')
    end

    context 'with valid event callback' do
      let(:valid_reaction_event_body) do
        {
          type: 'event_callback',
          event: { type: 'reaction_added', user: 'U123456', reaction: 'thumbs_up' }
        }.to_json
      end

      it 'triggers post_to_notion on valid reaction' do
        post '/slack/events', valid_reaction_event_body, { 'CONTENT_TYPE' => 'application/json' }

        # 追加: レスポンスボディを出力
        puts last_response.body

        expect(NotionPagePoster).to have_received(:post_to_notion).once
        expect(last_response).to be_ok
      end
    end

    context 'with invalid JSON' do
      it 'returns 400 for invalid JSON format' do
        post '/slack/events', '{ invalid json', { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('Invalid JSON format')
      end
    end
  end
end
