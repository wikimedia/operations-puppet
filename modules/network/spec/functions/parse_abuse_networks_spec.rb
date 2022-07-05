# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

abuse_networks = {
  'blocked_nets' => {
    'context' => ['ferm', 'varnish'],
    'networks' => ['192.0.2.1/25'],
  },
  'bot_blocked_nets' => {
    'context' => ['varnish'],
    'networks' => ['192.0.2.128/25'],
  },
  'public_cloud_nets' => {
    'context' => ['varnish'],
    'networks' => ['198.51.100.0/24', '203.0.113.0/24', '2001:db8::1/128'],
  }
}
ferm_parsed = {
  'blocked_nets' => {
    'context' => ['ferm', 'varnish'],
    'networks' => ['192.0.2.1/25'],
  },
}
varnish_parsed = {
  'blocked_nets' => {
    'context' => ['ferm', 'varnish'],
    'networks' => ['192.0.2.1/25'],
  },
  'bot_blocked_nets' => {
    'context' => ['varnish'],
    'networks' => ['192.0.2.128/25'],
  },
  'public_cloud_nets' => {
    'context' => ['varnish'],
    'networks' => ['198.51.100.0/24', '203.0.113.0/24', '2001:db8::1/128'],
  }
}
describe 'network::parse_abuse_nets' do
  it do
    is_expected.to run.with_params('ferm', abuse_networks).and_return(ferm_parsed)
  end
  it do
    is_expected.to run.with_params('varnish', abuse_networks).and_return(varnish_parsed)
  end
  it do
    is_expected.to run.with_params('foobar', abuse_networks).and_raise_error(
      ArgumentError, /expects a match for Network::Context/
    )
  end
  it do
    is_expected.to run.with_params('ferm', []).and_raise_error(
      ArgumentError, /expects a Hash value/
    )
  end
end
