require_relative '../../../../rake_modules/spec_helper'

describe 'profile::analytics::cluster::packages::common' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { is_expected.to compile }
    end
  end
end
