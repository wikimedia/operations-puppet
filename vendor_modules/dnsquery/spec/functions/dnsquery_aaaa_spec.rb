#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'
ipv6_pattern = %r{([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])}
describe 'dnsquery::aaaa' do
  it 'returns a list of IPv6 addresses when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Array
    expect(results).to all(match(ipv6_pattern))
  end

  it 'returns a list of IPv6 addresses when doing a lookup with different nameserver' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8' })
    expect(results).to be_a Array
    expect(results).to all(match(ipv6_pattern))
  end

  it 'returns a list of IPv6 addresses when doing a lookup with different ndots' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(results).to be_a Array
    expect(results).to all(match(ipv6_pattern))
  end

  it 'returns a list of IPv6 addresses when doing a lookup with different search' do
    results = subject.execute('google', { 'nameserver' => '8.8.8.8', 'search' => ['com'] })
    expect(results).to be_a Array
    expect(results).to all(match(ipv6_pattern))
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return(['::1']).
      with_lambda { ['::1'] }
    )
  end
end
