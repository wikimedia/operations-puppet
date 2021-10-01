require_relative '../../../../rake_modules/spec_helper'

describe 'base::environment' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      it { should compile }
    end
  end
end
