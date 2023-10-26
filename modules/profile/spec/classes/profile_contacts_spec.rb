require_relative '../../../../rake_modules/spec_helper'

describe 'profile::contacts' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts  }
      let(:params) { { } }
      let(:node_params) {{ '_role' => 'sretest' }}

      context "Defaults" do
        it { is_expected.to compile.with_all_deps }
      end
      context "add contacts" do
        let(:params) { super().merge(role_contacts: ['Infrastructure Foundations']) }
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
