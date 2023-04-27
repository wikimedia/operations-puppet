#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::a' do
  it 'returns a list of IPv4 addresses when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(match(%r{^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$}))
  end

  it 'returns a list of IPv4 addresses when doing a lookup with updated namesrver' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8' })
    expect(results).to be_a Array
    expect(results).to all(match(%r{^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$}))
  end

  it 'returns a list of IPv4 addresses when doing a lookup with updated ndots' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(results).to be_a Array
    expect(results).to all(match(%r{^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$}))
  end

  it 'returns a list of IPv4 addresses when doing a lookup with updated search' do
    results = subject.execute('google', { 'nameserver' => '8.8.8.8', 'search' => ['com'] })
    expect(results).to be_a Array
    expect(results).to all(match(%r{^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$}))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return(['127.0.0.1']).
      with_lambda { ['127.0.0.1'] }
    )
  end
end
