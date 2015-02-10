#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'pick_initscript' do
  before :each do
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("foo"))
    @scope = Puppet::Parser::Scope.new(@compiler)
  end

  it 'Returns false if no init script provided' do
    should run.with_params('systemd', false, false, false).and_return(false)
  end

  it 'Returns systemd if provided, sysvinit otherwise' do
    should run.with_params('systemd', true, true, true).and_return('systemd')
    should run.with_params('systemd', false, true, true).and_return('sysvinit')
  end

  it 'Returns upstart if provided, sysvinit otherwise' do
    should run.with_params('upstart', true, true, true).and_return('upstart')
    should run.with_params('upstart', true, false, true).and_return('sysvinit')
  end

  it 'Fails if on systemd and only upstart is provided, and vice versa' do
    should run.with_params('upstart', true, false, false).and_raise(Puppet::ArgumentError)
    should run.with_params('systemd', false, true, false).and_raise(Puppet::ArgumentError)
  end

end
