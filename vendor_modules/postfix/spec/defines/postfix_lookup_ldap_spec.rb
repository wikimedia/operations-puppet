require 'spec_helper'

describe 'postfix::lookup::ldap' do
  let(:title) do
    '/etc/postfix/test.cf'
  end

  let(:params) do
    {
      search_base: 'dc=example,dc=com',
      server_host: [
        '192.0.2.1',
        [
          '192.0.2.1',
          389,
        ],
        '2001:db8::1',
        [
          '2001:db8::1',
          389,
        ],
        'ldap.example.com',
        [
          'ldap.example.com',
          389,
        ],
        'ldap://ldap.example.com',
      ],
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/postfix/test.cf').with_content(<<-EOS.gsub(%r{^ {8}}, '')) }
        # !!! Managed by Puppet !!!

        search_base = dc=example,dc=com
        server_host = 192.0.2.1, 192.0.2.1:389, [2001:db8::1], [2001:db8::1]:389, ldap.example.com, ldap.example.com:389, ldap://ldap.example.com
        EOS
      it { is_expected.to contain_postfix__lookup__ldap('/etc/postfix/test.cf') }
    end
  end
end
