# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
describe 'profile::gerrit' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          ldap_config: {},
          ipv4: '198.51.100.1',
          ipv6: '2001:DB8::CAFE',
          bind_service_ip: true,
          host: 'gerrit.example.org',
          backups_enabled: true,
          backup_set: 'gerrit-backup',
          ssh_allowed_hosts: ['gerrit.example.org'],
          config: 'gerrit.config.erb',
          use_acmechief: true,
          replica_hosts: ['gerrit-replica.example.org'],
          daemon_user: 'gerrit2',
          scap_user: 'gerrit-deploy',
          manage_scap_user: true,
          scap_key_name: 'gerrit',
          enable_monitoring: true,
          replication: {},
          ssh_host_key: 'ssh_host_key',
          git_dir: '/srv/gerrit/git',
          java_home: '/usr/lib/jvm/java-11-openjdk-amd64',
        }
      }
      let(:pre_condition) {
          """
          service {'apache2': }
          function wmflib::role::hosts($role) {
            ['gerrit1001.example.org', 'gerrit2002.example.org']
          }
          """
      }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
