require 'spec_helper'

require 'rack/test'

# test rack class
class TestRack
  def call(_env)
    [404, {}, []]
  end
end

describe 'Integration' do
  include Rack::Test::Methods

  def app
    @middleware
  end

  def post_json(uri, body)
    post(uri, MultiJson.dump(body), 'CONTENT_TYPE' => 'application/json')
  end

  # @return [Hash]
  def parsed_last_response
    MultiJson.load(last_response.body)
  end

  before :each do
    @test_rack = TestRack.new
    @middleware = Clickatell::Catcher::Rack::Middleware.new(@test_rack)
    Clickatell::Catcher::Rack::SharedArray.new.clear
  end

  it 'return 404' do
    get '/'
    expect(last_response.status).to eq(404)
  end

  describe 'POST /rest/message' do
    context 'successfull message' do
      before :each do
        post_json '/rest/message', 'text' => 'This is a message', 'to' => ['27711234567']
      end

      it 'returns 200' do
        expect(last_response).to be_ok
      end

      it 'adds the message' do
        expect(@middleware.messages).to contain_exactly(
          'text' => 'This is a message', 'to' => ['27711234567'], 'added_at' => kind_of(Time)
        )
      end

      it 'has accepted body' do
        expect(parsed_last_response).to eq('data' => { 'message' => [
                                             { 'accepted' => true,
                                               'to' => '27711234567',
                                               'apiMessageId' => '1' }
                                           ] })
      end

      it 'is application/json' do
        expect(last_response.headers['Content-Type']).to eq('application/json')
      end
    end
  end

  describe 'GET /rest/message' do
    def add_message(message)
      @middleware.add_message(MultiJson.dump(message))
    end

    before :each do
      add_message('text' => 'This is a sample', 'to' => ['44711112222'])
      get '/rest/message'
    end

    it 'returns 200' do
      expect(last_response).to be_ok
    end

    it 'is text/html' do
      expect(last_response.headers['Content-Type']).to eq('text/html')
    end

    it 'has html content' do
      expect(last_response.body).to include('<html>')
      expect(last_response.body).to include('This is a sample')
      expect(last_response.body).to include('44711112222')
    end
  end
end
