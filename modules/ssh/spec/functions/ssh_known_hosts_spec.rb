# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

with_hostnames = {
  'foo.example.org' => {
    'type' => 'rsa',
    'key'  => 'some key',
    'host_aliases' => ['foo', '192.0.2.1', '2001:db8::1'],
  },
  'bar.example.org' => {
    'type' => 'rsa',
    'key'  => 'some key',
  },
}
without_hostnames = {
  'foo.example.org' => {
    'type' => 'rsa',
    'key'  => 'some key',
    'host_aliases' => ['192.0.2.1', '2001:db8::1'],
  },
  'bar.example.org' => {
    'type' => 'rsa',
    'key'  => 'some key',
    'host_aliases' => [],
  },
}

describe 'ssh::known_hosts' do
  let(:pre_condition) do
    "
    function wmflib::puppetdb_query($pql) {
      return [
        {
          'certname' => 'foo.example.org',
          'title'    => 'foo.example.org',
          'parameters' => {
            'type' => 'rsa',
            'key'  => 'some key',
            'host_aliases' => ['foo', '192.0.2.1', '2001:db8::1'],
          },
        },
        {
          'certname' => 'bar.example.org',
          'title'    => 'bar.example.org',
          'parameters' => {
            'type' => 'rsa',
            'key'  => 'some key',
          },
        },
      ]
    }
    "
  end
  context 'with defaults' do
    it { is_expected.to run.and_return(with_hostnames) }
    it { is_expected.to run.with_params(false).and_return(without_hostnames) }
  end
end
