require 'spec_helper'

describe 'Postfix::Type::Lookup::Memcache::Host' do
  it { is_expected.to allow_value('192.0.2.1') }
  it { is_expected.to allow_value('2001:db8::1') }
  it { is_expected.to allow_value('memcache.example.com') }
  it { is_expected.to allow_value(['192.0.2.1', 11_211]) }
  it { is_expected.to allow_value(['2001:db8::1', 11_211]) }
  it { is_expected.to allow_value(['memcache.example.com', 11_211]) }
  it { is_expected.to allow_value(['inet', '192.0.2.1']) }
  it { is_expected.to allow_value(['inet', '2001:db8::1']) }
  it { is_expected.to allow_value(['inet', 'memcache.example.com']) }
  it { is_expected.to allow_value(['inet', '192.0.2.1', 11_211]) }
  it { is_expected.to allow_value(['inet', '2001:db8::1', 11_211]) }
  it { is_expected.to allow_value(['inet', 'memcache.example.com', 11_211]) }
  it { is_expected.to allow_value(['unix', '/var/lib/memcache.sock']) }
  it { is_expected.not_to allow_value(['inet', '/var/lib/memcache.sock']) }
  it { is_expected.not_to allow_value(['unix', '192.0.2.1']) }
end
