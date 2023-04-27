#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'
mx = {
  'preference' => 10,
  'exchange' => 'mx.exampl.org',
}
describe 'dnsquery::mx' do
  it 'returns a list of MX records when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['preference']).to be_a Integer
      expect(res['exchange']).to be_a String
    end
  end

  it 'returns a list of MX records when doing a lookup with update nameserver' do
    results = subject.execute('google.com', { 'nameserver' => ['8.8.8.8'] })
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['preference']).to be_a Integer
      expect(res['exchange']).to be_a String
    end
  end

  it 'returns a list of MX records when doing a lookup with update ndots' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['preference']).to be_a Integer
      expect(res['exchange']).to be_a String
    end
  end

  it 'returns a list of MX records when doing a lookup with update search' do
    results = subject.execute('google', { 'nameserver' => '8.8.8.8', 'search' => ['com'] })
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['preference']).to be_a Integer
      expect(res['exchange']).to be_a String
    end
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return([mx]).
      with_lambda { [mx] }
    )
  end
end
