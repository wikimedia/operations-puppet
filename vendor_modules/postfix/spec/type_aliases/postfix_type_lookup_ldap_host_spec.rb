require 'spec_helper'

describe 'Postfix::Type::Lookup::LDAP::Host' do
  it { is_expected.to allow_value('192.0.2.1') }
  it { is_expected.to allow_value('2001:db8::1') }
  it { is_expected.to allow_value('ldap.example.com') }
  it { is_expected.to allow_value(['192.0.2.1', 389]) }
  it { is_expected.to allow_value(['2001:db8::1', 389]) }
  it { is_expected.to allow_value(['ldap.example.com', 389]) }
  it { is_expected.to allow_value('ldap://ldap.example.com') }
  it { is_expected.to allow_value('ldap://ldap.example.com:389') }
end
