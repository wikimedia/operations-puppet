# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'spicerack' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          tcpircbot_host: 'tcp.exampl.org',
          tcpircbot_port: 42,
          http_proxy: 'proxy.exampl.org',
          cookbooks_dirs: ['/srv/cookbook'],
          modules: {},
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
