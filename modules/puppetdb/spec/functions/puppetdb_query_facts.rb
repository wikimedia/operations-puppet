# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'puppetdb::query_facts' do
  describe 'one fact' do
    let(:pre_condition) do
      "function puppetdb_query($pql) {
        [{
          'certname' => 'foo',
          'name'     => 'ipaddress',
          'value'    => '192.0.2.42'
        }]
      }"
    end
    it { is_expected.to run.with_params(['ipaddress']).and_return({'foo' => {'ipaddress' => '192.0.2.42'}}) }
  end
  describe 'multiple fact' do
    let(:pre_condition) do
      "function puppetdb_query($pql) {
        [
          {
            'certname' => 'foo',
            'name'     => 'ipaddress',
            'value'    => '192.0.2.42'
          },
          {
            'certname' => 'foo',
            'name'     => 'fqdn',
            'value'    => 'foo.example.com'
          },
          {
            'certname' => 'foo',
            'name'     => 'kernel',
            'value'    => 'Linux'
          }
        ]
      }"
    end
    it do
      is_expected.to run.with_params(['ipaddress'])
        .and_return({
          'foo' => {
            'ipaddress' => '192.0.2.42',
            'fqdn' => 'foo.example.com',
            'kernel' => 'Linux',
          }
        })
    end
  end
end
