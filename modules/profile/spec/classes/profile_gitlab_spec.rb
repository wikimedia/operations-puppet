# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::gitlab' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node_params) {{ '_role' => 'gitlab' }}
      let(:params) do
        {
          service_name: 'gitlab.exampl.org',
          service_ip_v4: '192.0.2.42',
          service_ip_v6: '2001:db8::42',
          ssh_listen_addresses: ['192.0.2.42'],
          nginx_listen_addresses: ['192.0.2.42'],
        }
      end

      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
