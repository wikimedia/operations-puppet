require_relative '../../../../rake_modules/spec_helper'

describe 'zuul' do
    on_supported_os(WMFConfig.test_on).each do |os, facts|
      context "On #{os}" do
        let(:facts) { facts }
        let(:pre_condition) {
          "define scap::target($deploy_user) {}"
        }
        it { is_expected.to compile }
    end
  end
end
