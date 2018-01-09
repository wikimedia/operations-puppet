#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'pick_initscript' do
  it 'Returns false if no init script provided' do
    should run.with_params('apache2', 'systemd', false, false, false, false, true).and_return(false)
  end

  it 'Returns systemd if provided, sysvinit otherwise' do
    should run.with_params('apache2', 'systemd', true, false, true, true, true).and_return('systemd')
    should run.with_params('apache2', 'systemd', false, false, true, true, true).and_return('sysvinit')
  end

  it 'Returns upstart if provided, sysvinit otherwise' do
    should run.with_params('apache2', 'upstart', true, false, true, true, true).and_return('upstart')
    should run.with_params('apache2', 'upstart', true, false, false, true, true).and_return('sysvinit')
  end

  it 'Fails if on systemd and only upstart is provided, and vice versa' do
    should run.with_params('apache2', 'upstart', true, false, false, false, true).and_raise_error(ArgumentError)
    should run.with_params('apache2', 'systemd', false, false, true, false, true).and_raise_error(ArgumentError)
  end

  it 'Returns false on upstart if only systemd is provided, and strict is false' do
    should run.with_params('apache2', 'upstart', true, false, false, false, false).and_return(false)
  end
end
