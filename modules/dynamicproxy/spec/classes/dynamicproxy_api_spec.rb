# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'dynamicproxy::api' do
  on_supported_os(WMFConfig.test_on(11, 12)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          'keystone_api_url'         => 'https://keystone.someregion.wikimediacloud.org',
          'dns_updater_username'     => 'dns_username',
          'dns_updater_password'     => 'secret1',
          'dns_updater_project'      => 'dns_project',
          'token_validator_username' => 'token_username',
          'token_validator_password' => 'secret2',
          'token_validator_project'  => 'token_project',
          'mariadb_host'             => 'somedb.cloudinfra.someregion.wikimedia.cloud',
          'mariadb_db'               => 'webproxy',
          'mariadb_username'         => 'webproxy',
          'mariadb_password'         => 'secret3',
          'redis_primary_host'       => 'someredis.proxy.someregion.wikimedia.cloud',
          'proxy_dns_ipv4'           => '192.0.2.123',
          'supported_zones'          => {
            'zone1.example.' => {
              'id'             => 'aaaaaaaaaaa',
              'project'        => 'zone1dotexample',
              'acmechief_cert' => 'certname',
              'deprecated'     => false,
              'default'        => true,
              'shared'         => true,
            },
            'zone2.example.' => {
              'id'             => 'bbbbbbbbbb',
              'project'        => 'someproject',
              'acmechief_cert' => 'certname2',
              'deprecated'     => false,
              'default'        => false,
              'shared'         => false,
            },
          },
          'acme_certname'            => 'somecert',
          'ssl_settings'             => ['ssl_dhparam /etc/ssl/dhparam.pem;'],
        }
      end

      context 'in writable mode' do
        let(:params)  { super().merge(read_only: false) }

        describe 'compiles without errors' do
          it { is_expected.to compile.with_all_deps }
        end
      end

      context 'in read-only mode' do
        let(:params)  { super().merge(read_only: true) }

        describe 'compiles without errors' do
          it { is_expected.to compile.with_all_deps }
        end
      end
    end
  end
end
