require 'spec_helper'

describe 'Postfix::Type::Lookup::PgSQL::Host' do
  it { is_expected.to allow_value('192.0.2.1') }
  it { is_expected.to allow_value('2001:db8::1') }
  it { is_expected.to allow_value('pgsql.example.com') }
  it { is_expected.to allow_value(['192.0.2.1', 5432]) }
  it { is_expected.to allow_value(['2001:db8::1', 5432]) }
  it { is_expected.to allow_value(['pgsql.example.com', 5432]) }
  it { is_expected.to allow_value(['inet', '192.0.2.1']) }
  it { is_expected.to allow_value(['inet', '2001:db8::1']) }
  it { is_expected.to allow_value(['inet', 'pgsql.example.com']) }
  it { is_expected.to allow_value(['inet', '192.0.2.1', 5432]) }
  it { is_expected.to allow_value(['inet', '2001:db8::1', 5432]) }
  it { is_expected.to allow_value(['inet', 'pgsql.example.com', 5432]) }
  it { is_expected.to allow_value(['unix', '/var/lib/pgsql.sock']) }
  it { is_expected.not_to allow_value(['inet', '/var/lib/pgsql.sock']) }
  it { is_expected.not_to allow_value(['unix', '192.0.2.1']) }
end
