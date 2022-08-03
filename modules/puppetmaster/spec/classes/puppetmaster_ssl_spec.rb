require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::ssl' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'service{"apache2": }' }

      it { is_expected.to compile }
    end
  end
end
