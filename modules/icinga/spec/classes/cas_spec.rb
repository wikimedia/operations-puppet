require_relative '../../../../rake_modules/spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'icinga::cas' do
  let(:node) { 'foobar.example.com' }
  let(:params) do
    {
      # virtual_host: "icinga.example.com",
      # cookie_path: "/var/cache/apache2/mod_auth_cas/",
      # certificate_path: "/etc/ssl/certs/",
      # login_url: "https://idp.example.org/cas/login",
      # validate_url: "https://idp.example.org/cas/samlValidate",
      # authn_header: "CAS-User",
      # attribute_prefix: "X-CAS-",
      # debug: false,
      # validate_saml: true,
      # apache_owner: "www-data",
      # apache_group: "www-data",
      required_groups: ['foo', 'bar'],
    }
  end
  let(:pre_condition) { "include httpd" }

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__mod_conf('auth_cas') }
        it do
          is_expected.to contain_file('/var/cache/apache2/mod_auth_cas/').with(
            ensure: 'directory',
            owner: 'www-data',
            group: 'www-data'
          )
        end
        it do
          is_expected.to contain_httpd__site('icinga.example.com').with_content(
            /AuthType\s+CAS
            \s+CASAuthNHeader\s+CAS-User
            \s+\#\s+Implicit\s+RequireAny
            \s+Require\s+cas-attribute\s+memberOf:foo
            \s+Require\s+cas-attribute\s+memberOf:bar
            /x
          )
        end
      end
    end
  end
end
