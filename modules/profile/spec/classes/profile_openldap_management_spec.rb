require_relative '../../../../rake_modules/spec_helper'

describe 'profile::openldap::management' do
  on_supported_os(WMFConfig.test_on).each do |_os, facts|
    let(:facts) { facts }
    let(:pre_condition) { 'class passwords::phabricator { $offboarding_script_token = "test" }' }
    context 'timer is active' do
      let(:params) { {timer_active: true} }
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_systemd__timer__job('daily_account_consistency_check')
                        .with_ensure('present')
      }
    end
    context 'timer is inactive' do
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_systemd__timer__job('daily_account_consistency_check')
                        .with_ensure('absent')
      }
    end
  end
end
