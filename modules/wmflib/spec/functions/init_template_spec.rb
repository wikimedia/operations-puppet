require_relative '../../../../rake_modules/spec_helper'

describe 'init_template' do
  before(:each) { allow(scope).to receive(:lookupvar).with('module_name').and_return('wmflib') }

  it 'correctly renders the template' do
    is_expected.to run.with_params('fooservice', 'systemd').and_return("This is a test!\n")
  end
end
