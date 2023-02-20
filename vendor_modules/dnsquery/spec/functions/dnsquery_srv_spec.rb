#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'
srv = {
  'priority' => 1,
  'weight' => 1,
  'port' => 80,
  'target' => 'srv.example.com',
}
describe 'dnsquery::srv' do
  it 'returns a list of SRV records when doing a lookup' do
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

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return([srv]).
      with_lambda { [srv] }
    )
  end
end
