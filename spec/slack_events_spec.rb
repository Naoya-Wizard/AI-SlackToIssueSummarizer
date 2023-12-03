require 'spec_helper'
require 'rack/test'
require_relative '../app.rb' # Sinatraアプリケーションファイルへのパス

describe 'Slack Events API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
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
      let(:event_callback_body) do
        {
          type: 'event_callback',
          event: { type: 'reaction_added', reaction: 'thumbsup' }
        }.to_json
      end

      it 'handles reaction_added events' do
        post '/slack/events', event_callback_body, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response).to be_ok
        expect(last_response.body).to include('Reaction added: thumbsup')
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
