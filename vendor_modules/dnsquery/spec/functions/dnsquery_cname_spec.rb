#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dnsquery::cname' do
  it 'returns a CNAME destination when doing a lookup' do
    result = subject.execute('en.wikipedia.org')
    expect(result).to be_a String
  end

  it 'raises an error on empty reply' do
    is_expected.to run.
      with_params('foo.example.com').
      and_raise_error(Resolv::ResolvError)
  end
end
