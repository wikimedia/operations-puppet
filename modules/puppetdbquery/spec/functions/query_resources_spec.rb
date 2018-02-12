#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe 'query_resources' do
  it do
    resource = { 'tags' => %w(apache package class __node_regexp__apache httpd node),
                 'file' => '/etc/puppetlabs/code/environments/production/modules/apache/manifests/init.pp',
                 'type' => 'Package',
                 'title' => 'httpd',
                 'line' => 103,
                 'resource' => 'c239274125740582bc181dfcb7dcb3e476ada592',
                 'environment' => 'production',
                 'certname' => 'apache4.puppetexplorer.io',
                 'parameters' => { 'ensure' => 'installed', 'name' => 'apache2', 'notify' => 'Class[Apache::Service]' },
                 'exported' => false }
    PuppetDB::Connection.any_instance.expects(:query)
      .with(:resources, ['and', ['and', ['=', 'type', 'Package'], ['=', 'title', 'httpd'], ['=', 'exported', false]], ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['hostname']], ['=', 'value', 'apache4']]]]]])
      .returns [resource]
    should run.with_params('hostname=apache4', 'package[httpd]')
      .and_return([resource])
  end
end
