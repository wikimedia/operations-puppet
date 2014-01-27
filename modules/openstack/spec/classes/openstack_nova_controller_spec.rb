require 'spec_helper'

describe 'openstack::nova::controller' do

  let :default_params do
    {
      :public_address         => '127.0.0.1',
      :db_host                => '127.0.0.1',
      :api_bind_address       => '0.0.0.0',
      :rabbit_password        => 'rabbit_pass',
      :nova_user_password     => 'nova_user_pass',
      :neutron_user_password  => 'neutron_user_pass',
      :nova_db_password       => 'nova_db_pass',
      :neutron                => true,
      :memcached_servers      => false,
      :metadata_shared_secret => 'secret'
    }
  end

  let :facts do
    {:osfamily => 'Debian' }
  end

  let :params do
    default_params
  end

  it { should contain_class('openstack::nova::controller') }

  context 'when configuring neutron' do

    it 'should configure nova with neutron' do

      should contain_class('nova::rabbitmq').with(
        :userid                 => 'openstack',
        :password               => 'rabbit_pass',
        :enabled                => true,
        :cluster_disk_nodes     => false,
        :virtual_host           => '/'
      )
      should contain_class('nova').with(
        :sql_connection       => 'mysql://nova:nova_db_pass@127.0.0.1/nova',
        :rabbit_userid        => 'openstack',
        :rabbit_password      => 'rabbit_pass',
        :rabbit_virtual_host  => '/',
        :image_service        => 'nova.image.glance.GlanceImageService',
        :glance_api_servers   => '127.0.0.1:9292',
        :debug                => false,
        :verbose              => false,
        :rabbit_hosts         => false,
        :rabbit_host          => '127.0.0.1',
        :memcached_servers    => false,
        :use_syslog           => false,
        :log_facility         => 'LOG_USER'
      )

      should contain_class('nova::api').with(
        :enabled                              => true,
        :admin_tenant_name                    => 'services',
        :admin_user                           => 'nova',
        :admin_password                       => 'nova_user_pass',
        :enabled_apis                         => 'ec2,osapi_compute,metadata',
        :api_bind_address                     => '0.0.0.0',
        :auth_host                            => '127.0.0.1',
        :neutron_metadata_proxy_shared_secret => 'secret'
      )

      should contain_class('nova::network::neutron').with(
        :neutron_admin_password    => 'neutron_user_pass',
        :neutron_auth_strategy     => 'keystone',
        :neutron_url               => "http://127.0.0.1:9696",
        :neutron_admin_tenant_name => 'services',
        :neutron_admin_username    => 'neutron',
        :neutron_admin_auth_url    => "http://127.0.0.1:35357/v2.0",
        :security_group_api        => 'neutron'
      )

      ['nova::scheduler', 'nova::objectstore', 'nova::cert', 'nova::consoleauth', 'nova::conductor'].each do |x|
        should contain_class(x).with_enabled(true)
      end

      should contain_class('nova::vncproxy').with(
        :host    => '127.0.0.1',
        :enabled => true
      )
    end
  end

  context 'when configuring memcached' do
    let :params do
      default_params.merge(
        :memcached_servers => ['memcached01:11211', 'memcached02:11211']
      )
    end
    it 'should configure nova with memcached' do
      should contain_class('nova').with(
        :memcached_servers => ['memcached01:11211', 'memcached02:11211']
      )
    end
  end

  context 'when configuring SSL' do
    let :params do
      default_params.merge(
        :db_ssl => true,
        :db_ssl_ca => '/etc/mysql/ca.pem'
      )
    end
    it 'should configure SSL' do
      should contain_class('nova').with(
        :sql_connection       => 'mysql://nova:nova_db_pass@127.0.0.1/nova?ssl_ca=/etc/mysql/ca.pem'
      )
    end
  end

  context 'with custom syslog settings' do
    let :params do
      default_params.merge(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
    it do
      should contain_class('nova').with(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
  end

end
