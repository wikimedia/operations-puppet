#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dns_ptr' do
  it 'returns a list of PTR results when doing a lookup' do
    results = subject.execute('8.8.8.8.in-addr.arpa')
    expect(results).to be_a Array
    expect(results).to all(be_a(String))
  end
end
