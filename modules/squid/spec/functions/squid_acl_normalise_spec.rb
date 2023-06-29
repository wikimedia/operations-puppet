# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

input = {
  'test_acl' => {
    'task'     => 'T1234',
    'port'     => 9876,
    'dst_type' => 'host',
    'src'      => ['sretest'],
    'dst'      => ['bastion.example.org']
  }
}
output = {
  'test_acl' => {
    'task'     => 'T1234',
    'port'     => 9876,
    'dst_type' => 'host',
    'src'      => ['192.0.2.1', '2001:db8::1'],
    'dst'      => ['198.51.100.1', '198.51.100.2', '2001:db8:1::1', '2001:db8:2::1']
  }
}

describe 'squid::acl::normalise' do
  let(:pre_condition) do
    "function wmflib::role::ips($role) {
      ['192.0.2.1', '2001:db8::1']
    }
    function dnsquery::lookup($host) {
      ['198.51.100.1', '198.51.100.2', '2001:db8:1::1', '2001:db8:2::1']
    }"
  end
  it { is_expected.to run.with_params(input).and_return(output) }
end
