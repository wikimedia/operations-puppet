# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'query_service::deploy::scap', :type => :class do
  let(:pre_condition) do
    'file { ["/var/log/query_service", "/etc/query_service", "/etc/wdqs/vars.yaml"]:
      ensure => present,
      content => "",
    }'
  end

  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          deploy_user: 'deploy-service',
          username:    'blazegraph',
          package_dir: '/srv/deployment/wdqs/wdqs',
          deploy_name: 'wdqs'
        }
      end

      context 'with systemd' do
        it { is_expected.to contain_sudo__user('scap_deploy-service_wdqs-updater').with('user' => 'deploy-service') }
        it { is_expected.to contain_sudo__user('scap_deploy-service_wdqs-blazegraph').with('user' => 'deploy-service') }
      end
    end
  end
end
