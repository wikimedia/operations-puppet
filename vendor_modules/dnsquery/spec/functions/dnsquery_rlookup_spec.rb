#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::rlookup' do
  it 'returns list of results from a reverse lookup' do
    results = subject.execute('8.8.4.4')
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('0.0.0.0').
      and_return(['foo.example.com']).
      with_lambda { ['foo.example.com'] }
    )
  end
end
