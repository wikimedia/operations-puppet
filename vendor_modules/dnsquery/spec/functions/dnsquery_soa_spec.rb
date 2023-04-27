# frozen_string_literal: true

require 'spec_helper'
soa = {
  'expire' => 3600,
  'minimum' => 3600,
  'mname' => 'ns.example.com',
  'refresh' => 3600,
  'retry' => 3600,
  'rname' => 'mail.example.com',
  'serial' => 1,
}
describe 'dnsquery::soa' do
  it 'must return a hash of SOA-records parts when doing a lookup' do
    results = subject.execute('google.com')
    expect(results).to be_a Hash
    expect(results['expire']).to be_a Integer
    expect(results['minimum']).to be_a Integer
    expect(results['mname']).to be_a String
    expect(results['refresh']).to be_a Integer
    expect(results['retry']).to be_a Integer
    expect(results['rname']).to be_a String
    expect(results['serial']).to be_a Integer
  end

  it 'must return a hash of SOA-records parts when doing a lookup with update nameserver' do
    results = subject.execute('google.com', { 'nameserver' => ['8.8.8.8'] })
    expect(results).to be_a Hash
    expect(results['expire']).to be_a Integer
    expect(results['minimum']).to be_a Integer
    expect(results['mname']).to be_a String
    expect(results['refresh']).to be_a Integer
    expect(results['retry']).to be_a Integer
    expect(results['rname']).to be_a String
    expect(results['serial']).to be_a Integer
  end

  it 'must return a hash of SOA-records parts when doing a lookup with update ndots' do
    results = subject.execute('google.com', { 'nameserver' => '8.8.8.8', 'ndots' => 1 })
    expect(results).to be_a Hash
    expect(results['expire']).to be_a Integer
    expect(results['minimum']).to be_a Integer
    expect(results['mname']).to be_a String
    expect(results['refresh']).to be_a Integer
    expect(results['retry']).to be_a Integer
    expect(results['rname']).to be_a String
    expect(results['serial']).to be_a Integer
  end

  it 'must return a hash of SOA-records parts when doing a lookup with update search' do
    results = subject.execute('google', { 'nameserver' => '8.8.8.8', 'search' => ['com'] })
    expect(results).to be_a Hash
    expect(results['expire']).to be_a Integer
    expect(results['minimum']).to be_a Integer
    expect(results['mname']).to be_a String
    expect(results['refresh']).to be_a Integer
    expect(results['retry']).to be_a Integer
    expect(results['rname']).to be_a String
    expect(results['serial']).to be_a Integer
  end

  it 'returns lambda value if result is empty' do
    is_expected.to(
      run.
      with_params('foo.example.com').
      and_return(soa).
      with_lambda { soa }
    )
  end
end
