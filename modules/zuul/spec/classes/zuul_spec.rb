require_relative '../../../../rake_modules/spec_helper'

describe 'zuul' do
    # Only tested on Bullseye (11) which is the OS version of contint server.
    # The whole system will be replaced with a newer Zuul on a different infra.
    on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
      context "On #{os}" do
        let(:facts) { facts }
        let(:pre_condition) {
          "define scap::target($deploy_user) {}"
        }
        it { is_expected.to compile }
    end
  end
end
