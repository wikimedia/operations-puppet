# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'envoyproxy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      context "On ensure present" do
        let(:params) { {ensure: 'present', admin_port: 8081, pkg_name: 'envoyproxy', service_cluster: 'test' }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('envoyproxy') }
        it { is_expected.to contain_file('/etc/envoy').with_ensure('directory')}
        it { is_expected.to contain_file('/etc/envoy/envoy.yaml').with_owner('root') }
      end
      context "On ensure absent" do
        let(:params) { {:ensure => 'absent', :admin_port => 8081, pkg_name: 'envoyproxy',  service_cluster: 'test'  }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('envoyproxy').with_ensure('absent') }
        it { is_expected.to contain_file('/etc/envoy').with_ensure('absent')}
      end
    end
  end
end
