#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::cname' do
  it 'returns a CNAME destination when doing a lookup' do
    result = subject.execute('en.wikipedia.org')
    expect(result).to be_a String
  end

  it 'returns a CNAME destination when doing a lookup update nameserver' do
    result = subject.execute('en.wikipedia.org', { 'nameserver' => ['8.8.8.8'] })
    expect(result).to be_a String
  end

  it 'returns a CNAME destination when doing a lookup with updated ndots' do
    result = subject.execute('en.wikipedia.org', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(result).to be_a String
  end

  it 'returns a CNAME destination when doing a lookup with updated search' do
    result = subject.execute('en.wikipedia', { 'nameserver' => '8.8.8.8', 'search' => ['org'] })
    expect(result).to be_a String
  end

  it 'raises an error on empty reply' do
    is_expected.to run.
      with_params('foo.example.com').
      and_raise_error(Resolv::ResolvError)
  end
end
