#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::ptr' do
  it 'returns a list of PTR results when doing a lookup' do
    results = subject.execute('8.8.8.8.in-addr.arpa')
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('1.2.0.192.in-addr.arpa').
      and_return(['ptr.exampl.org']).
      with_lambda { ['ptr.exampl.org'] }
    )
  end
end
