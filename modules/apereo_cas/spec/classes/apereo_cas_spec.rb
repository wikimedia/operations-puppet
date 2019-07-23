# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9', '10'],
    }
  ]
}

describe 'apereo_cas' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) { { keystore_source: 'puppet:///modules/apereo_cas/thekeystore' } }
      it { is_expected.to compile.with_all_deps }
      ['/srv', '/srv/cas', '/srv/cas/overlay-template',
       '/etc/cas', '/etc/cas/services', '/etc/cas/config'].each do |dir|
        it do
          is_expected.to contain_file(dir).with_ensure('directory')
        end
      end
      it do
        is_expected.to contain_git__clone('cas-overlay-template').with(
          origin: 'https://github.com/b4ldr/cas-overlay-template',
          directory: '/srv/cas/overlay-template'
        )
        is_expected.to contain_file('/etc/cas/config/cas.properties').with(
          owner: 'root',
          group: 'root',
          mode: '0400'
        ).with_content(
          %r{^cas.server.name=https://foo.example.com:8443$}
        ).with_content(
          %r{^cas.server.prefix=https://foo.example.com:8443/cas$}
        ).with_content(
          %r{^cas.serviceRegistry.json.location=file:/etc/cas/services$}
        ).with_content(
          /^cas.authn.ldap\[0\].principalAttributeList=cn,memberOf,mail$/
        ).with_content(
          /^cas.authn.ldap\[0\].type=AUTHENTICATED$/
        ).with_content(
          /^cas.authn.ldap\[0\].connectionStrategy=ACTIVE_PASSIVE$/
        ).with_content(
          %r{^cas.authn.ldap\[0\].ldapurl=ldap://ldap.example.org:389$}
        ).with_content(
          /^cas.authn.ldap\[0\].useStartTLS=true$/
        ).with_content(
          /^cas.authn.ldap\[0\].basedn=dc=,example,dc=org/
        ).with_content(
          /^cas.authn.ldap\[0\].searchFilter=cn={user}$/
        ).with_content(
          /^cas.authn.ldap\[0\].binddn=cn=user,dc=example,dc=org$/
        ).with_content(
          /^cas.authn.ldap\[0\].bindcredential=changeme$/
        ).with_content(
          /^cas.authn.accept.users=$/
        ).with_content(
          /^logging.level.org.apereo=WARN$/
        )
        is_expected.to contain_file('/etc/cas/config/log4j2.xml').with(
          owner: 'root',
          group: 'root',
          mode: '0400'
        )
        is_expected.to contain_file('/etc/cas/thekeystore').with(
          owner: 'root',
          group: 'root',
          mode: '0400'
        )
        is_expected.to contain_exec('build cas war').with(
          command: '/srv/cas/overlay-template/build.sh package',
          creates: '/srv/cas/overlay-template/build/libs/cas.war',
          cwd: '/srv/cas/overlay-template'
        )
        is_expected.to contain_exec('update cas war').with(
          command: '/srv/cas/overlay-template/build.sh update',
          cwd: '/srv/cas/overlay-template',
          refreshonly: true
        )
        is_expected.to contain_systemd__service('cas').with_content(
          %r{ExecStart=/usr/bin/java -jar /srv/cas/overlay-template/build/libs/cas.war}
        )
      end
    end
  end
end
