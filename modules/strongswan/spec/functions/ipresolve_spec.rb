require 'spec_helper'

describe 'ipresolve' do
  before :each do
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new('foo'))
    @scope = Puppet::Parser::Scope.new(@compiler)
  end
  it 'should be called with two parameters' do
    should run.and_raise_error(ArgumentError)
    should run.with_params(['google.com']).and_raise_error(ArgumentError)
  end

  it 'expects second parameter to be 4 or 6' do
    should_not run.with_params('google.com', '4').and_raise_error(ArgumentError)
    should_not run.with_params('google.com', '6').and_raise_error(ArgumentError)
  end

  it 'returns the resolved address as a string' do
    r = Resolv::DNS::Resource::IN::A.new(Resolv::IPv4.create('74.125.29.113'))
    Resolv::DNS.any_instance.stub(:getresource => r)
    dns = DNSCached.new
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A).should eq('74.125.29.113')
  end

  it 'uses cached results on subsequent lookups' do
    r = Resolv::DNS::Resource::IN::A.new(Resolv::IPv4.create('74.125.29.113'))
    resolv = double('Resolv::DNS', :getresource => r)
    resolv.should_receive(:getresource).once
    dns = DNSCached.new
    dns.dns = resolv
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A)
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A)
  end

  it 'not uses cached results if ttl is zero' do
    r = Resolv::DNS::Resource::IN::A.new(Resolv::IPv4.create('74.125.29.113'))
    resolv = double('Resolv::DNS', :getresource => r)
    resolv.should_receive(:getresource).twice
    dns = DNSCached.new(nil, 0)
    dns.dns = resolv
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A)
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A)
  end

  it 'uses cached result in case of failure' do
    r = Resolv::DNS::Resource::IN::A.new(Resolv::IPv4.create('74.125.29.113'))
    dns = DNSCached.new(nil,0)
    dns.dns.stub(:getresource => r)
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A)
    dns.dns.stub(:getresource => 'ciao')
    dns.get_resource('google.com', Resolv::DNS::Resource::IN::A).should eq('74.125.29.113')
  end
end
