#! /usr/bin/env ruby -S rspec

require 'spec_helper'
require 'puppetdb/connection'

describe 'query_facts' do
  it do
    PuppetDB::Connection.any_instance.expects(:query)
      .with(:facts, ['or', ['=', 'name', 'ipaddress']], {:extract => [:certname, :name, :value]})
      .returns [
        { 'certname' => 'apache4.puppetexplorer.io', 'environment' => 'production', 'name' => 'ipaddress', 'value' => '172.31.6.80' }
      ]
    should run.with_params('', ['ipaddress']).and_return('apache4.puppetexplorer.io' => { 'ipaddress' => '172.31.6.80' })
  end

  it do
    PuppetDB::Connection.any_instance.expects(:query)
      .with(:facts, ['or', ['=', 'name', 'ipaddress'], ['=', 'name', 'network_eth0']], {:extract => [:certname, :name, :value]})
      .returns [
        { 'certname' => 'apache4.puppetexplorer.io', 'environment' => 'production', 'name' => 'ipaddress', 'value' => '172.31.6.80' },
        { 'certname' => 'apache4.puppetexplorer.io', 'environment' => 'production', 'name' => 'network_eth0', 'value' => '172.31.0.0' }
      ]
    should run.with_params('', ['ipaddress', 'network_eth0']).and_return('apache4.puppetexplorer.io' => { 'ipaddress' => '172.31.6.80', 'network_eth0' => '172.31.0.0' })
  end

  context 'with a nested fact parameter' do
    it do
      PuppetDB::Connection.any_instance.expects(:query)
        .with(:facts, ['or', ['=', 'name', 'ipaddress'], ['=', 'name', 'networking']], {:extract => [:certname, :name, :value]})
        .returns [
          { 'certname' => 'apache4.puppetexplorer.io', 'environment' => 'production', 'name' => 'ipaddress', 'value' => '172.31.6.80' },
          {
            'certname' => 'apache4.puppetexplorer.io',
            'environment' => 'production',
            'name' => 'networking',
            'value' => {
              'interfaces' => {
                'eth0' => {
                  'ip' => '172.31.6.80',
                  'network' => '172.31.0.0',
                },
                'eth1' => {
                  'ip' => '172.32.6.80',
                  'network' => '172.32.0.0',
                },
                'bond0' => {},
              }
            }
          }
        ]
      should run.with_params('', ['ipaddress', 'networking.interfaces.eth0.ip']).and_return('apache4.puppetexplorer.io' => { 'ipaddress' => '172.31.6.80', 'networking_interfaces_eth0_ip' => '172.31.6.80' })
    end
  end
end
