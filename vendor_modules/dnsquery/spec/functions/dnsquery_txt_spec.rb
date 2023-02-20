#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::txt' do
  it 'returns a list of lists of strings when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(be_a(Array))
    expect(results).to all(all(be_a(String)))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return([['foobar']]).
      with_lambda { [['foobar']] }
    )
  end
end
