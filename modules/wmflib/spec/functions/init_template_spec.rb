#!/usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'init_template' do
  before(:each) { scope.expects(:lookupvar).with('module_name').returns('foo') }

  it 'correctly renders the template' do
    is_expected.to run.with_params('fooservice', 'systemd').and_return("This is a test!\n")
  end
end
