require 'spec_helper'

describe 'Postfix::Type::Lookup::MySQL::Host' do
  it { is_expected.to allow_value('192.0.2.1') }
  it { is_expected.to allow_value('2001:db8::1') }
  it { is_expected.to allow_value('mysql.example.com') }
  it { is_expected.to allow_value(['192.0.2.1', 3306]) }
  it { is_expected.to allow_value(['2001:db8::1', 3306]) }
  it { is_expected.to allow_value(['mysql.example.com', 3306]) }
  it { is_expected.to allow_value(['inet', '192.0.2.1']) }
  it { is_expected.to allow_value(['inet', '2001:db8::1']) }
  it { is_expected.to allow_value(['inet', 'mysql.example.com']) }
  it { is_expected.to allow_value(['inet', '192.0.2.1', 3306]) }
  it { is_expected.to allow_value(['inet', '2001:db8::1', 3306]) }
  it { is_expected.to allow_value(['inet', 'mysql.example.com', 3306]) }
  it { is_expected.to allow_value(['unix', '/var/lib/mysql.sock']) }
  it { is_expected.not_to allow_value(['inet', '/var/lib/mysql.sock']) }
  it { is_expected.not_to allow_value(['unix', '192.0.2.1']) }
end
