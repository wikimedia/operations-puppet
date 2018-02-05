require 'spec_helper'

describe 'profile::openldap::management' do
  let(:pre_condition) { 'class passwords::phabricator { $offboarding_script_token = "test" }' }
  context 'cron is active' do
    let(:node_params) { { :site => 'testsite', :realm => 'production', :test_name => 'openldap_management_cron_active'} }
    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_cron('daily_account_consistency_check')
                       .with_ensure('present')
    }
  end
  context 'cron is inactive' do
    let(:node_params) { { :site => 'testsite', :realm => 'production', :test_name => 'openldap_management_cron_inactive'} }
    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_cron('daily_account_consistency_check')
                       .with_ensure('absent')
    }
  end
end
