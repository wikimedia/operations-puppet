# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::admin' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:node_params) { { '_role' => 'ceph/admin' } }
      # firewall::service resolves the host names of the peers.
      let(:pre_condition) do
        "function dnsquery::lookup($host, $force_ipv6) { ['192.0.2.42', '2001:db8::42'] }"
      end
      let(:site) { 'eqiad' }
      let(:fqdn) { 'ceph-admin1001.eqiad.wmnet' }
      let(:node) { fqdn }
      let(:facts) do
        os_facts.merge({
          'site' => site,
          'networking' => os_facts[:networking].merge({ 'fqdn' => fqdn })
        })
      end

      context 'on the eqiad administration host' do
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

        describe 'copies of the snapshots' do
          it 'stops the cleartext rsync daemon' do
            is_expected.to contain_class('rsync::server').with(
              ensure_service: 'stopped', address: '127.0.0.1'
            )
            is_expected.to contain_class('rsync::server::stunnel')
          end

          it 'serves the snapshots of its own site to the codfw host only' do
            is_expected.to contain_rsync__server__module('tofu-state-eqiad').with(
              path: '/srv/tofu-state-snapshots/eqiad',
              read_only: 'yes',
              hosts_allow: ['ceph-admin2001.codfw.wmnet']
            )
            is_expected.not_to contain_rsync__server__module('tofu-state-codfw')
          end

          it 'pulls the snapshots of the codfw site over TLS, without deletes' do
            is_expected.to contain_file('/usr/local/sbin/sync-tofu-state-codfw')
              .with_content(%r{--rsh /usr/local/sbin/sync-tofu-state-codfw-ssl-wrapper})
              .with_content(%r{rsync://ceph-admin2001\.codfw\.wmnet/tofu-state-codfw /srv/tofu-state-snapshots/codfw/$})
              .without_content(/--delete/)
            is_expected.to contain_systemd__timer__job('rsync-tofu-state-codfw').with_ensure('present')
            is_expected.to contain_systemd__timer__job('rsync-tofu-state-eqiad').with_ensure('absent')
          end

          it 'keeps every copy under /srv/tofu-state-snapshots' do
            copies = catalogue.resources.select { |resource| resource.type == 'Rsync::Quickdatacopy' }
            expect(copies.map(&:title)).to contain_exactly('tofu-state-eqiad', 'tofu-state-codfw')
            copies.each do |copy|
              expect(copy[:module_path]).to start_with('/srv/tofu-state-snapshots/')
            end
          end
        end
      end

      context 'on the codfw administration host' do
        let(:site) { 'codfw' }
        let(:fqdn) { 'ceph-admin2001.codfw.wmnet' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/srv/tofu-state-snapshots/codfw') }
        it do
          is_expected.to contain_rsync__server__module('tofu-state-codfw').with(
            path: '/srv/tofu-state-snapshots/codfw',
            hosts_allow: ['ceph-admin1001.eqiad.wmnet']
          )
        end
        it { is_expected.not_to contain_rsync__server__module('tofu-state-eqiad') }
        it { is_expected.to contain_systemd__timer__job('rsync-tofu-state-eqiad').with_ensure('present') }
        it { is_expected.to contain_systemd__timer__job('rsync-tofu-state-codfw').with_ensure('absent') }
      end

      context 'when state_hosts names another host for this site' do
        let(:fqdn) { 'ceph-admin2001.codfw.wmnet' }

        it do
          is_expected.to compile.and_raise_error(
            /state_hosts must map eqiad to ceph-admin2001\.codfw\.wmnet/
          )
        end
      end
    end
  end
end
