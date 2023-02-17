# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbox' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          service_hostname: 'netbox.example.org',
          secret_key: 'secret',
          ldap_password: 'secret',
          db_host: 'db.example.org',
          db_password: 'secret',
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'test validators' do
        let(:params) { super().merge(validators: ['dcim.interface', 'ipam.ipaddress']) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/netbox/configuration.py')
            .with_content(/
                          CUSTOM_VALIDATORS\s=\s\{\s+
                            'dcim\.interface':\s\(\s'validators\.dcim\.interface\.Main',\s\),\s+
                            'ipam\.ipaddress':\s\(\s'validators\.ipam\.ipaddress\.Main',\s\)\s+
                            \}
                          /x)
        end
      end
    end
  end
end
