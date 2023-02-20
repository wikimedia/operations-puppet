#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dns_srv' do
  it 'returns a list of MX records when doing a lookup' do
    results = subject.execute('_spotify-client._tcp.spotify.com')
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['priority']).to be_a Integer
      expect(res['weight']).to be_a Integer
      expect(res['port']).to be_a Integer
      expect(res['target']).to be_a String
    end
  end
end
