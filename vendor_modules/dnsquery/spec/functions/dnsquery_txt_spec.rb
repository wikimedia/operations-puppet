#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::txt' do
  it 'returns a list of strings when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns a list of lists of strings when doing a lookup with update nameserver' do
    results = subject.execute('google.com', { 'nameserver' => ['8.8.8.8'] })
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns a list of lists of strings when doing a lookup with update ndots' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns a list of lists of strings when doing a lookup with update search' do
    results = subject.execute('google', { 'nameserver' => '8.8.8.8', 'search' => ['com'] })
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return(['foobar']).
      with_lambda { ['foobar'] }
    )
  end
end
