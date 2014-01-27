require 'spec_helper'

describe 'openstack::auth_file' do

  describe "when only passing default class parameters" do

    let :params do
      { :admin_password => 'admin' }
    end

    it 'should create a openrc file' do
      verify_contents(subject, '/root/openrc', [
        'export OS_NO_CACHE=\'true\'',
        'export OS_TENANT_NAME=\'openstack\'',
        'export OS_USERNAME=\'admin\'',
        'export OS_PASSWORD=\'admin\'',
        'export OS_AUTH_URL=\'http://127.0.0.1:5000/v2.0/\'',
        'export OS_AUTH_STRATEGY=\'keystone\'',
        'export OS_REGION_NAME=\'RegionOne\'',
        'export CINDER_ENDPOINT_TYPE=\'publicURL\'',
        'export GLANCE_ENDPOINT_TYPE=\'publicURL\'',
        'export KEYSTONE_ENDPOINT_TYPE=\'publicURL\'',
        'export NOVA_ENDPOINT_TYPE=\'publicURL\'',
        'export NEUTRON_ENDPOINT_TYPE=\'publicURL\''
      ])
    end
  end

  describe 'when overriding parameters' do

    let :params do
      {
        :controller_node          => '127.0.0.2',
        :admin_password           => 'admin',
        :admin_tenant             => 'admin',
        :keystone_admin_token     => 'keystone',
        :cinder_endpoint_type     => 'privateURL',
        :glance_endpoint_type     => 'privateURL',
        :keystone_endpoint_type   => 'privateURL',
        :nova_endpoint_type       => 'privateURL',
        :neutron_endpoint_type    => 'privateURL',
      }
    end

    it 'should create a openrc file' do
      verify_contents(subject, '/root/openrc', [
        'export OS_SERVICE_TOKEN=\'keystone\'',
        'export OS_SERVICE_ENDPOINT=\'http://127.0.0.2:35357/v2.0/\'',
        'export OS_NO_CACHE=\'true\'',
        'export OS_TENANT_NAME=\'admin\'',
        'export OS_USERNAME=\'admin\'',
        'export OS_PASSWORD=\'admin\'',
        'export OS_AUTH_URL=\'http://127.0.0.2:5000/v2.0/\'',
        'export OS_AUTH_STRATEGY=\'keystone\'',
        'export OS_REGION_NAME=\'RegionOne\'',
        'export CINDER_ENDPOINT_TYPE=\'privateURL\'',
        'export GLANCE_ENDPOINT_TYPE=\'privateURL\'',
        'export KEYSTONE_ENDPOINT_TYPE=\'privateURL\'',
        'export NOVA_ENDPOINT_TYPE=\'privateURL\'',
        'export NEUTRON_ENDPOINT_TYPE=\'privateURL\''
      ])
    end
  end

  describe "handle password and token with single quotes" do

    let :params do
      {
        :admin_password       => 'singlequote\'',
        :keystone_admin_token => 'key\'stone'
      }
    end

    it 'should create a openrc file' do
      verify_contents(subject, '/root/openrc', [
        'export OS_SERVICE_TOKEN=\'key\\\'stone\'',
        'export OS_PASSWORD=\'singlequote\\\'\'',
      ])
    end
  end

end
