require 'spec_helper'

describe Clickatell::Sandbox::Rack::MessageAdder do
  let(:messages) { [] }
  subject { Clickatell::Sandbox::Rack::MessageAdder.new(messages) }

  def add_json_message(message)
    subject.add(MultiJson.dump(message))
  end

  def rack_status
    subject.rack_response[0]
  end

  def rack_headers
    subject.rack_response[1]
  end

  def parsed_rack_response
    MultiJson.load(subject.rack_response[2].first)
  end

  def parsed_rack_response_message
    parsed_rack_response['data']['message']
  end

  describe 'successful single recipient' do
    before :each do
      add_json_message('text' => 'This is a message', 'to' => ['27711234567'])
    end

    it 'adds the message' do
      expect(messages).to contain_exactly('text' => 'This is a message', 'to' => ['27711234567'])
    end

    it 'sets correct status' do
      expect(rack_status).to eq(200)
    end

    it 'sets correct headers' do
      expect(rack_headers).to eq('Content-Type' => 'application/json')
    end

    it 'sets correct message body' do
      expect(parsed_rack_response_message).to contain_exactly('accepted' => true,
                                                              'to' => '27711234567',
                                                              'apiMessageId' => '1')
    end
  end

  describe 'successful 2 recipients' do
    before :each do
      add_json_message('text' => 'Hello everyone', 'to' => %w(27711234567 27711112222))
    end

    it 'adds the message' do
      expect(messages).to contain_exactly('text' => 'Hello everyone',
                                          'to' => %w(27711234567 27711112222))
    end

    it 'sets correct status' do
      expect(rack_status).to eq(200)
    end

    it 'sets correct headers' do
      expect(rack_headers).to eq('Content-Type' => 'application/json')
    end

    it 'sets correct message body' do
      expect(parsed_rack_response_message).to contain_exactly({ 'accepted' => true,
                                                                'to' => '27711234567',
                                                                'apiMessageId' => '1' },
                                                              'accepted' => true,
                                                              'to' => '27711112222',
                                                              'apiMessageId' => '2')
    end
  end

  describe 'sending 2 successful message' do
    before :each do
      add_json_message('text' => 'Hello', 'to' => ['27711234567'])
      add_json_message('text' => 'Goodbye', 'to' => ['27711234567'])
    end

    it 'adds the message to the front' do
      expect(messages).to eq([{ 'text' => 'Goodbye', 'to' => ['27711234567'] },
                              { 'text' => 'Hello', 'to' => ['27711234567'] }])
    end

    it 'sets correct status' do
      expect(rack_status).to eq(200)
    end

    it 'sets correct headers' do
      expect(rack_headers).to eq('Content-Type' => 'application/json')
    end

    it 'sets correct message body (apiMessageId increments from last message)' do
      expect(parsed_rack_response_message).to contain_exactly('accepted' => true,
                                                              'to' => '27711234567',
                                                              'apiMessageId' => '2')
    end
  end

  describe 'limit 25 messages' do
    before :each do
      27.times do |i|
        add_json_message('text' => i.to_s, 'to' => ['27711234567'])
      end
    end

    it 'keeps the last 25 messages' do
      expect(messages.size).to eq(25)
    end

    it 'remove older messages first' do
      expect(messages.first).to eq('text' => '26', 'to' => ['27711234567'])
      expect(messages.last).to eq('text' => '2', 'to' => ['27711234567'])
    end
  end
end
