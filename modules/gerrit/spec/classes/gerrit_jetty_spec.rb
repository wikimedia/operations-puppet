require_relative '../../../../rake_modules/spec_helper'

describe 'gerrit::jetty' do
  let(:params) {
    {
      :host          => 'gerrit.example.org',
      :ipv4          => '192.0.2.42',
      :ipv6          => '2001:db8::1',
      :java_home     => '/path/to/java_home',
      :ldap_config   => {
        :'ro-server' => 'ldapro.example.org',
        :'base-dn'   => 'dc=example,dc=org',
      },
      :scap_user     => 'gerrit-deployer',
      :scap_key_name => 'gerrit-ssh-key',
    }
  }
  let(:pre_condition) do
    '''
    User{"gerrit-deployer":}
    Group{"gerrit-deployer":}
    '''
  end
  it { should compile }
end
