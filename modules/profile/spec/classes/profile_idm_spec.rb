# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::idm' do
  on_supported_os(WMFConfig.test_on(12, 13)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          service_fqdn: 'idm.example.org',
          django_secret_key: '12345',
          django_mysql_db_host: 'db.local',
          django_mysql_db_password: 'secret',
          ldap_dn: 'ou=people,dc=example,dc=org',
          ldap_dn_password: 'secret',
          mediawiki_key: '12345',
          mediawiki_secret: 'secret',
          mediawiki_callback: 'https://idm.example.org',
          redis_master: 'redis.local',
          gitlab_token: '12345abcde',
          phabricator_token: '12345abcde',
          gerrit_user: 'gerrit',
          gerrit_password: 'secret',
          enable_monitoring: false,
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      describe "bitu configuration settings" do
        it do
          is_expected.to contain_file('/etc/bitu/settings.py') \
          .with_content(/^SIGNUP_EMAIL_VALIDATORS*/)
        end
      end
    end
  end
end
