# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
filteruser = {
  'filteruser' => {
    'ensure' => 'present',
    'gid' => 500,
    'uid' => 1042,
    'name' => 'test',
    'email' => 'test@example.org',
    'ssh_keys' => []
  }
}
users = {
  'groups' => {
    'all-users' => {
      'description' => 'Global group that includes all users',
      'gid' => 600,
      'members' => [],
      'privileges' => []
    }
  },
  'users' => {
    'testuser1' => {
      'ensure' => 'present',
      'gid' => 500,
      'uid' => 1042,
      'name' => 'test',
      'email' => 'test@example.org',
      'ssh_keys' => []
    }
  }.merge(filteruser)
}
describe 'admin::get_users' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:loadyaml, :type => :rvalue) {|_args| users}
  end
  it { is_expected.to run.and_return(users['users']) }
  it { is_expected.to run.with_params(['filteruser']).and_return(filteruser) }
  it { is_expected.to run.with_params('filteruser').and_return(filteruser) }
end
