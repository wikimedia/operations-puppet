# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'dynamicproxy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          'ssl_settings'             => ['ssl_dhparam /etc/ssl/dhparam.pem;'],
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
          'redis_primary'            => 'foo-instance.project.eqiad1.wikimedia.cloud',
          'banned_ips'               => ['192.0.2.1'],
          'blocked_user_agent_regex' => 'FooUA1|FooUA2',
          'blocked_referer_regex'    => 'foosite\\.example',
          'xff_fqdns'                => ['fooproject.wmcloud.org'],
          'rate_limit_requests'      => 100,
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
