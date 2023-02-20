#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'

describe 'dns_mx' do
  it 'returns a list of MX records when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(be_a(Hash))
    results.each do |res|
      expect(res['preference']).to be_a Integer
      expect(res['exchange']).to be_a String
    end
  end
end
