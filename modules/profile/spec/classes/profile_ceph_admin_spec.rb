# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::admin' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:node) { 'ceph-admin1001.eqiad.wmnet' }
      let(:node_params) { { '_role' => 'ceph/admin' } }
      let(:facts) do
        os_facts.merge({
          'networking' => os_facts[:networking].merge({ 'fqdn' => 'ceph-admin1001.eqiad.wmnet' })
        })
      end

      it { is_expected.to compile.with_all_deps }

      describe 'OpenTofu state snapshots' do
        [
          '/srv/tofu-state-snapshots',
          '/srv/tofu-state-snapshots/eqiad',
          '/srv/tofu-state-snapshots/.staging',
        ].each do |dir|
          it do
            is_expected.to contain_file(dir).with(
              ensure: 'directory', owner: 'root', group: 'root', mode: '0700'
            )
          end
        end

        it do
          is_expected.to contain_systemd__timer__job('tofu-state-snapshot').with(
            command: '/usr/local/sbin/tofu-state-snapshot ' \
                     '--snapshot-dir /srv/tofu-state-snapshots/eqiad ' \
                     '--staging-dir /srv/tofu-state-snapshots/.staging',
            user: 'root',
            team: 'Data Platform'
          )
        end

        it 'removes the start limit of the service' do
          is_expected.to contain_file(
            '/etc/systemd/system/tofu-state-snapshot.service.d/tofu-state-snapshot-start-limit.conf'
          ).with_content("[Unit]\nStartLimitIntervalSec=0\n")
        end

        it 'watches the state file of each root module' do
          is_expected.to contain_file('/lib/systemd/system/tofu-state-snapshot.path')
            .with_content(%r{
              ^\[Path\]\n
              PathChanged=/srv/tofu-infra/resources/rgw_accounts/terraform\.tfstate\n
              PathChanged=/srv/tofu-infra/resources/rgw_bucket_access/terraform\.tfstate\n
              PathChanged=/srv/tofu-infra/resources/rgw_global_bucket/terraform\.tfstate\n
              PathChanged=/srv/tofu-infra/resources/rgw_global_user/terraform\.tfstate\n
              Unit=tofu-state-snapshot\.service\n
            }x)
        end

        it do
          is_expected.to contain_service('tofu-state-snapshot.path')
            .with(ensure: 'running', enable: true, provider: 'systemd')
            .that_requires('Systemd::Unit[tofu-state-snapshot.service]')
            .that_subscribes_to('Systemd::Unit[tofu-state-snapshot.path]')
        end
      end
    end
  end
end
