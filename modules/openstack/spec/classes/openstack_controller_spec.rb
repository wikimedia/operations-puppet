require 'spec_helper'

describe 'openstack::controller' do

  # minimum set of default parameters
  let :default_params do
    {
      :private_interface       => 'eth0',
      :public_interface        => 'eth1',
      :internal_address        => '127.0.0.1',
      :public_address          => '10.0.0.1',
      :admin_email             => 'some_user@some_fake_email_address.foo',
      :admin_password          => 'ChangeMe',
      :rabbit_password         => 'rabbit_pw',
      :rabbit_cluster_nodes    => false,
      :rabbit_virtual_host     => '/',
      :keystone_db_password    => 'keystone_pass',
      :keystone_admin_token    => 'keystone_admin_token',
      :keystone_token_driver   => 'keystone.token.backends.sql.Token',
      :keystone_host           => '127.0.0.1',
      :glance_registry_host    => '0.0.0.0',
      :glance_db_password      => 'glance_pass',
      :glance_user_password    => 'glance_pass',
      :nova_bind_address       => '0.0.0.0',
      :nova_db_password        => 'nova_pass',
      :nova_user_password      => 'nova_pass',
      :nova_memcached_servers  => false,
      :cinder_db_password      => 'cinder_pass',
      :cinder_user_password    => 'cinder_pass',
      :secret_key              => 'secret_key',
      :mysql_root_password     => 'sql_pass',
      :neutron                 => false,
      :vncproxy_host           => '10.0.0.1',
      :nova_admin_tenant_name  => 'services',
      :nova_admin_user         => 'nova',
      :enabled_apis            => 'ec2,osapi_compute,metadata',
      :physical_network        => 'default'
    }
  end

  let :facts do
    {
      :operatingsystem        => 'Ubuntu',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '12.04',
      :puppetversion          => '2.7.x',
      :memorysize             => '2GB',
      :processorcount         => '2',
      :concat_basedir         => '/var/lib/puppet/concat',
    }
  end

  let :params do
    default_params
  end

  context 'database' do

    context 'with unsupported db type' do

      let :params do
        default_params.merge({:db_type => 'sqlite'})
      end

      it do
        expect { subject }.to raise_error(Puppet::Error)
      end

    end

    context 'with default mysql params' do

      let :params do
        default_params.merge(
          :enabled                => true,
          :db_type                => 'mysql',
          :neutron                => true,
          :metadata_shared_secret => 'secret',
          :bridge_interface       => 'eth1',
          :neutron_user_password  => 'q_pass',
          :neutron_db_password    => 'q_db_pass',
          :cinder                 => true
        )
      end

      it 'should configure mysql server' do
        param_value(subject, 'class', 'mysql::server', 'enabled').should be_true
        config_hash = param_value(subject, 'class', 'mysql::server', 'config_hash')
        config_hash['bind_address'].should == '0.0.0.0'
        config_hash['root_password'].should == 'sql_pass'
      end

      it 'should contain openstack db config' do
         should contain_class('keystone::db::mysql').with(
           :user          => 'keystone',
           :password      => 'keystone_pass',
           :dbname        => 'keystone',
           :allowed_hosts => '%'
         )
         should contain_class('glance::db::mysql').with(
           :user          => 'glance',
           :password      => 'glance_pass',
           :dbname        => 'glance',
           :allowed_hosts => '%'
         )
         should contain_class('nova::db::mysql').with(
           :user          => 'nova',
           :password      => 'nova_pass',
           :dbname        => 'nova',
           :allowed_hosts => '%'
         )
         should contain_class('cinder::db::mysql').with(
           :user          => 'cinder',
           :password      => 'cinder_pass',
           :dbname        => 'cinder',
           :allowed_hosts => '%'
         )
         should contain_class('neutron::db::mysql').with(
           :user          => 'neutron',
           :password      => 'q_db_pass',
           :dbname        => 'neutron',
           :allowed_hosts => '%'
         )
      end


      it { should contain_class('mysql::server::account_security')}

    end

    context 'when cinder and neutron are false' do

      let :params do
        default_params.merge(
          :neutron => false,
          :cinder  => false
        )
      end
      it do
        should_not contain_class('neutron::db::mysql')
        should_not contain_class('cinder::db::mysql')
      end

    end

    context 'when not enabled' do

      let :params do
        default_params.merge(
          {:enabled => false}
        )
      end

      it 'should configure mysql server' do
        param_value(subject, 'class', 'mysql::server', 'enabled').should be_false
        config_hash = param_value(subject, 'class', 'mysql::server', 'config_hash')
        config_hash['bind_address'].should == '0.0.0.0'
        config_hash['root_password'].should == 'sql_pass'
      end

      ['keystone', 'nova', 'glance', 'cinder', 'neutron'].each do |x|
        it { should_not contain_class("#{x}::db::mysql") }
      end
    end

    context 'when account security is not enabled' do
      let :params do
        default_params.merge(
          {:mysql_account_security => false}
        )
      end

      it { should_not contain_class('mysql::server::account_security')}
    end

    context 'with default SSL params, disabled' do

      it 'SSL in mysql should be disabled' do
        config_hash = param_value(subject, 'class', 'mysql::server', 'config_hash')
        config_hash['ssl'].should == false
      end

    end

    context 'SSL is enabled' do
      let :params do
        default_params.merge(
          :mysql_ssl => true,
          :mysql_ca => '/etc/mysql/ca.pem',
          :mysql_cert => '/etc/mysql/server.pem',
          :mysql_key => '/etc/mysql/server.key'
        )
      end

      it 'should configure mysql server' do
        config_hash = param_value(subject, 'class', 'mysql::server', 'config_hash')
        config_hash['ssl'].should == true
        config_hash['ssl_ca'].should == '/etc/mysql/ca.pem'
        config_hash['ssl_cert'].should == '/etc/mysql/server.pem'
        config_hash['ssl_key'].should == '/etc/mysql/server.key'
      end

    end

  end

  context 'keystone' do

    context 'with default params' do

      let :params do
        default_params
      end

      it 'should configure default keystone configuration' do

        should contain_class('openstack::keystone').with(
          :swift                  => false,
          :swift_user_password    => false,
          :swift_public_address   => false,
          :swift_internal_address => false,
          :swift_admin_address    => false,
          :use_syslog             => false,
          :log_facility           => 'LOG_USER'
        )

        should contain_class('keystone').with(
          :verbose        => false,
          :debug          => false,
          :catalog_type   => 'sql',
          :enabled        => true,
          :admin_token    => 'keystone_admin_token',
          :token_driver   => 'keystone.token.backends.sql.Token',
          :token_format   => 'PKI',
          :sql_connection => "mysql://keystone:keystone_pass@127.0.0.1/keystone"
        )

        should contain_class('keystone::roles::admin').with(
          :email        => 'some_user@some_fake_email_address.foo',
          :password     => 'ChangeMe',
          :admin_tenant => 'admin'
        )
        should contain_class('keystone::endpoint').with(
          :public_address   => '10.0.0.1',
          :public_protocol  => 'http',
          :internal_address => '127.0.0.1',
          :admin_address    => '127.0.0.1',
          :region           => 'RegionOne'
        )
        {
         'nova'     => 'nova_pass',
         'cinder'   => 'cinder_pass',
         'glance'   => 'glance_pass'

        }.each do |type, pw|
          should contain_class("#{type}::keystone::auth").with(
            :password         => pw,
            :public_address   => '10.0.0.1',
            :public_protocol  => 'http',
            :internal_address => '127.0.0.1',
            :admin_address    => '127.0.0.1',
            :region           => 'RegionOne'
          )
        end
      end
      context 'when configuring swift' do
        before :each do
          params.merge!(
            :swift                  => true,
            :swift_user_password    => 'foo',
            :swift_public_address   => '10.0.0.2',
            :swift_internal_address => '10.0.0.2',
            :swift_admin_address    => '10.0.0.2'
          )
        end
        it 'should configure swift auth in keystone' do
          should contain_class('openstack::keystone').with(
            :swift                  => true,
            :swift_user_password    => 'foo',
            :swift_public_address   => '10.0.0.2',
            :swift_internal_address => '10.0.0.2',
            :swift_admin_address    => '10.0.0.2'
          )
        end
      end
    end
    context 'when not enabled' do

      let :params do
        default_params.merge(:enabled => false)
      end

      it 'should not configure endpoints' do
        should contain_class('keystone').with(:enabled => false)
        should_not contain_class('keystone::roles::admin')
        should_not contain_class('keystone::endpoint')
        should_not contain_class('glance::keystone::auth')
        should_not contain_class('nova::keystone::auth')
      end
    end

    context 'when public_protocol is set to https' do

      let :params do
        default_params.merge(:public_protocol => 'https')
      end

      it 'should propagate it to the endpoints' do
        should contain_class('keystone::endpoint').with(:public_protocol => 'https')
        should contain_class('glance::keystone::auth').with(:public_protocol => 'https')
        should contain_class('nova::keystone::auth').with(:public_protocol => 'https')
        should contain_class('cinder::keystone::auth').with(:public_protocol => 'https')
      end
    end

    context 'with different public, internal and admin addresses' do
      let :params do
        default_params.merge(
          :public_address   => '1.1.1.1',
          :internal_address => '2.2.2.2',
          :admin_address    => '3.3.3.3'
        )
      end

      it 'should set addresses in subclasses' do
        should contain_class('keystone::endpoint').with(
          :public_address   => '1.1.1.1',
          :internal_address => '2.2.2.2',
          :admin_address    => '3.3.3.3'
        )

        ['nova', 'cinder', 'glance'].each do |type|
          should contain_class("#{type}::keystone::auth").with(
            :public_address   => '1.1.1.1',
            :internal_address => '2.2.2.2',
            :admin_address    => '3.3.3.3'
          )
        end
      end
    end

    context 'with mysql SSL enabled' do

      let :params do
        default_params.merge(
          :mysql_ssl => true,
          :mysql_ca => '/etc/mysql/ca.pem',
          :mysql_cert => '/etc/mysql/server.pem',
          :mysql_key => '/etc/mysql/server.key'
        )
      end

      it 'should configure keystone with SSL mysql connection' do
        should contain_class('keystone').with(
          :sql_connection => "mysql://keystone:keystone_pass@127.0.0.1/keystone?ssl_ca=/etc/mysql/ca.pem"
        )
      end
    end
  end

  it do
    should contain_class('memcached').with(
      :listen_ip => '127.0.0.1'
    )
  end



  context 'config for glance' do

    context 'when enabled' do
      it 'should contain enabled glance with defaults' do

        should contain_class('openstack::glance').with(
          :verbose           => false,
          :debug             => false,
          :registry_host     => '0.0.0.0',
          :enabled           => true,
          :use_syslog        => false,
          :log_facility      => 'LOG_USER'
        )

        should contain_class('glance::api').with(
          :verbose           => false,
          :debug             => false,
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass',
          :registry_host     => '0.0.0.0',
          :sql_connection    => 'mysql://glance:glance_pass@127.0.0.1/glance',
          :enabled           => true
        )

        should contain_class('glance::registry').with(
          :verbose           => false,
          :debug             => false,
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass',
          :sql_connection    => "mysql://glance:glance_pass@127.0.0.1/glance",
          :enabled           => true
        )

        should contain_class('glance::backend::file')
      end
    end
    context 'when not enabled' do

      let :params do
        default_params.merge(:enabled => false)
      end

      it 'should disable glance services' do
        should contain_class('glance::api').with(
          :enabled           => false
        )

        should contain_class('glance::registry').with(
          :enabled           => false
        )
      end
    end
    context 'when params are overridden' do

      let :params do
        default_params.merge(
          :verbose               => false,
          :debug                 => false,
          :glance_registry_host  => '127.0.0.2',
          :glance_user_password  => 'glance_pass2',
          :glance_db_password    => 'glance_pass3',
          :db_host               => '127.0.0.2',
          :sql_idle_timeout      => '30',
          :glance_db_user        => 'dan',
          :glance_db_dbname      => 'name',
          :glance_backend        => 'rbd',
          :glance_rbd_store_user => 'myuser',
          :glance_rbd_store_pool => 'mypool',
          :db_host               => '127.0.0.2',
          :use_syslog            => true,
          :log_facility          => 'LOG_LOCAL0'
        )
      end

      it 'should override params for glance' do
        should contain_class('openstack::glance').with(
          :verbose           => false,
          :debug             => false,
          :registry_host     => '127.0.0.2',
          :enabled           => true,
          :use_syslog        => true,
          :log_facility      => 'LOG_LOCAL0'
        )

        should contain_class('glance::api').with(
          :verbose           => false,
          :debug             => false,
          :registry_host     => '127.0.0.2',
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass2',
          :sql_connection    => 'mysql://dan:glance_pass3@127.0.0.2/name',
          :sql_idle_timeout  => '30'
        )

        should contain_class('glance::registry').with(
          :verbose           => false,
          :debug             => false,
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass2',
          :sql_connection    => "mysql://dan:glance_pass3@127.0.0.2/name"
        )
      end
    end

    context 'when the RBD backend is configured' do
       let :params do
        default_params.merge(
          :glance_backend        => 'rbd',
          :glance_rbd_store_user => 'myuser',
          :glance_rbd_store_pool => 'mypool'
        )

        should contain_class('glance::backend::rbd').with(
          :rbd_store_user => 'myuser',
          :rbd_store_pool => 'mypool'
        )
      end
    end

    context 'with mysql SSL enabled' do

      let :params do
        default_params.merge(
          :mysql_ssl => true,
          :mysql_ca => '/etc/mysql/ca.pem',
          :mysql_cert => '/etc/mysql/server.pem',
          :mysql_key => '/etc/mysql/server.key'
        )
      end

      it 'should configure glance with SSL mysql connection' do
        should contain_class('glance::api').with(
          :sql_connection    => "mysql://glance:glance_pass@127.0.0.1/glance?ssl_ca=/etc/mysql/ca.pem"
        )
      end
    end

  end

  context 'config for nova' do
    let :facts do
      {
        :operatingsystem        => 'Ubuntu',
        :osfamily               => 'Debian',
        :operatingsystemrelease => '12.04',
        :puppetversion          => '2.7.x',
        :memorysize             => '2GB',
        :processorcount         => '2',
        :concat_basedir         => '/var/lib/puppet/concat',
      }
    end

    context 'with default params' do

      it 'should contain enabled nova services' do
        should contain_class('openstack::nova::controller').with(
          :db_host                 => '127.0.0.1',
          :sql_idle_timeout        => '3600',
          :network_manager         => 'nova.network.manager.FlatDHCPManager',
          :network_config          => {},
          :floating_range          => false,
          :fixed_range             => '10.0.0.0/24',
          :public_address          => '10.0.0.1',
          :admin_address           => false,
          :internal_address        => '127.0.0.1',
          :auto_assign_floating_ip => false,
          :create_networks         => true,
          :num_networks            => 1,
          :multi_host              => false,
          :public_interface        => 'eth1',
          :private_interface       => 'eth0',
          :neutron                 => false,
          :neutron_user_password   => false,
          :metadata_shared_secret  => false,
          :security_group_api      => 'neutron',
          :nova_admin_tenant_name  => 'services',
          :nova_admin_user         => 'nova',
          :nova_user_password      => 'nova_pass',
          :nova_db_password        => 'nova_pass',
          :nova_db_user            => 'nova',
          :nova_db_dbname          => 'nova',
          :enabled_apis            => 'ec2,osapi_compute,metadata',
          :api_bind_address        => '0.0.0.0',
          :rabbit_user             => 'openstack',
          :rabbit_password         => 'rabbit_pw',
          :rabbit_hosts            => false,
          :rabbit_cluster_nodes    => false,
          :rabbit_virtual_host     => '/',
          :glance_api_servers      => '',
          :vnc_enabled             => true,
          :vncproxy_host           => '10.0.0.1',
          :use_syslog              => false,
          :log_facility            => 'LOG_USER',
          :debug                   => false,
          :verbose                 => false,
          :enabled                 => true
        )

        should_not contain_resources('nova_config').with_purge(true)
        should contain_class('nova::rabbitmq').with(
          :userid               => 'openstack',
          :password             => 'rabbit_pw',
          :cluster_disk_nodes   => false,
          :virtual_host         => '/',
          :enabled              => true
        )
        should contain_class('nova').with(
          :sql_connection      => 'mysql://nova:nova_pass@127.0.0.1/nova',
          :rabbit_host         => '127.0.0.1',
          :rabbit_hosts        => false,
          :rabbit_userid       => 'openstack',
          :rabbit_password     => 'rabbit_pw',
          :rabbit_virtual_host => '/',
          :image_service       => 'nova.image.glance.GlanceImageService',
          :glance_api_servers  => '10.0.0.1:9292',
          :debug               => false,
          :verbose             => false,
          :memcached_servers   => false
        )
        should contain_class('nova::api').with(
          :enabled           => true,
          :admin_tenant_name => 'services',
          :admin_user        => 'nova',
          :admin_password    => 'nova_pass',
          :enabled_apis      => 'ec2,osapi_compute,metadata',
          :auth_host         => '127.0.0.1',
          :api_bind_address  => '0.0.0.0'
        )
        should contain_class('nova::cert').with(:enabled => true)
        should contain_class('nova::consoleauth').with(:enabled => true)
        should contain_class('nova::scheduler').with(:enabled => true)
        should contain_class('nova::objectstore').with(:enabled => true)
        should contain_class('nova::conductor').with(:enabled => true)
        should contain_class('nova::vncproxy').with(
          :enabled         => true,
          :host            => '10.0.0.1'
        )
      end
      it { should_not contain_nova_config('DEFAULT/auto_assign_floating_ip') }
    end
    context 'when auto assign floating ip is assigned' do
      let :params do
        default_params.merge(:auto_assign_floating_ip => true)
      end
      it { should contain_nova_config('DEFAULT/auto_assign_floating_ip').with(:value => true)}
    end
    context 'when not enabled' do
      let :params do
        default_params.merge(:enabled => false)
      end
      it 'should disable everything' do
        should contain_class('nova::rabbitmq').with(:enabled => false)
        should contain_class('nova::api').with(:enabled => false)
        should contain_class('nova::cert').with(:enabled => false)
        should contain_class('nova::consoleauth').with(:enabled => false)
        should contain_class('nova::scheduler').with(:enabled => false)
        should contain_class('nova::objectstore').with(:enabled => false)
        should contain_class('nova::vncproxy').with(:enabled => false)
      end
    end
    context 'when params are overridden' do
      let :params do
        default_params.merge(
          :sql_idle_timeout => '30',
          :use_syslog       => true,
          :log_facility     => 'LOG_LOCAL0'
        )
      end
      it 'should override params for nova' do
        should contain_class('openstack::nova::controller').with(
          :sql_idle_timeout => '30',
          :use_syslog       => true,
          :log_facility     => 'LOG_LOCAL0'
        )

        should contain_class('nova').with(
          :sql_idle_timeout  => '30'
        )
      end
    end
  end

  context 'config for horizon' do

    it 'should contain enabled horizon' do
      should contain_class('horizon').with(
        :secret_key        => 'secret_key',
        :cache_server_ip   => '127.0.0.1',
        :cache_server_port => '11211',
        :horizon_app_links => false,
        :keystone_host     => '127.0.0.1'
      )
    end

    describe 'when horizon is disabled' do
      let :params do
        default_params.merge(:horizon => false)
      end
      it { should_not contain_class('horizon') }
    end

  end

  context 'cinder' do

    context 'when disabled' do
      let :params do
        default_params.merge(:cinder => false)
      end
      it 'should not contain cinder classes' do
        should_not contain_class('openstack::cinder::all')
        should_not contain_class('cinder')
        should_not contain_class('cinder::api')
        should_not contain_class('cinder::scheduler')
        should_not contain_class('cinder::volume')
      end
    end

    context 'when enabled' do
      let :params do
        default_params
      end
      it 'should configure cinder using defaults' do
        should contain_class('openstack::cinder::all').with(
          :bind_host          => '0.0.0.0',
          :sql_idle_timeout   => '3600',
          :keystone_password  => 'cinder_pass',
          :rabbit_userid      => 'openstack',
          :rabbit_password    => 'rabbit_pw',
          :rabbit_host        => '127.0.0.1',
          :rabbit_hosts       => false,
          :db_password        => 'cinder_pass',
          :db_dbname          => 'cinder',
          :db_user            => 'cinder',
          :db_type            => 'mysql',
          :db_host            => '127.0.0.1',
          :manage_volumes     => false,
          :volume_group       => 'cinder-volumes',
          :setup_test_volume  => false,
          :iscsi_ip_address   => '127.0.0.1',
          :use_syslog         => false,
          :log_facility       => 'LOG_USER',
          :enabled            => true,
          :debug              => false,
          :verbose            => false
        )

        should contain_class('cinder').with(
          :debug           => false,
          :verbose         => false,
          :sql_connection  => 'mysql://cinder:cinder_pass@127.0.0.1/cinder?charset=utf8',
          :rabbit_password => 'rabbit_pw'
        )
        should contain_class('cinder::api').with_keystone_password('cinder_pass')
        should contain_class('cinder::scheduler')
      end
    end

    context 'when overriding config' do
      let :params do
        default_params.merge(
          :debug                => true,
          :verbose              => true,
          :rabbit_host          => '127.0.0.1',
          :rabbit_hosts         => false,
          :rabbit_user          => 'rabbituser',
          :rabbit_password      => 'rabbit_pw2',
          :cinder_user_password => 'foo',
          :cinder_db_password   => 'bar',
          :cinder_db_user       => 'baz',
          :cinder_db_dbname     => 'blah',
          :sql_idle_timeout     => '30',
          :db_host              => '127.0.0.2',
          :use_syslog           => true,
          :log_facility         => 'LOG_LOCAL0'
        )
      end
      it 'should configure cinder using custom parameters' do
        should contain_class('openstack::cinder::all').with(
          :sql_idle_timeout   => '30',
          :keystone_password  => 'foo',
          :rabbit_userid      => 'rabbituser',
          :rabbit_password    => 'rabbit_pw2',
          :rabbit_host        => '127.0.0.1',
          :rabbit_hosts       => false,
          :db_password        => 'bar',
          :db_dbname          => 'blah',
          :db_user            => 'baz',
          :db_type            => 'mysql',
          :db_host            => '127.0.0.2',
          :use_syslog         => true,
          :log_facility       => 'LOG_LOCAL0',
          :debug              => true,
          :verbose            => true
        )


        should contain_class('cinder').with(
          :debug            => true,
          :verbose          => true,
          :sql_connection   => 'mysql://baz:bar@127.0.0.2/blah?charset=utf8',
          :sql_idle_timeout => '30',
          :rabbit_password  => 'rabbit_pw2',
          :rabbit_userid    => 'rabbituser'
        )
        should contain_class('cinder::api').with_keystone_password('foo')
        should contain_class('cinder::scheduler')
      end
    end

  end

  context 'network config' do

    context 'when neutron' do

      let :params do
        default_params.merge({
          :neutron                => true,
          :debug                  => true,
          :verbose                => true,
          :sql_idle_timeout       => '30',
          :neutron_user_password  => 'q_pass',
          :bridge_interface       => 'eth_27',
          :allow_overlapping_ips  => false,
          :internal_address       => '10.0.0.3',
          :neutron_db_password    => 'q_db_pass',
          :metadata_shared_secret => 'secret',
          :external_bridge_name   => 'br-ex'
        })
      end

      it { should_not contain_class('nova::network') }

      it { should contain_class('nova::network::neutron').with(:security_group_api => 'neutron') }

      it 'should configure neutron' do

        should contain_class('openstack::neutron').with(
          :db_host               => '127.0.0.1',
          :sql_idle_timeout      => '30',
          :rabbit_host           => '127.0.0.1',
          :rabbit_hosts          => false,
          :rabbit_user           => 'openstack',
          :rabbit_password       => 'rabbit_pw',
          :rabbit_virtual_host   => '/',
          :tenant_network_type   => 'gre',
          :ovs_enable_tunneling  => true,
          :allow_overlapping_ips => false,
          :ovs_local_ip          => '10.0.0.3',
          :bridge_uplinks        => ["br-ex:eth_27"],
          :bridge_mappings       => ["default:br-ex"],
          :enable_ovs_agent      => true,
          :firewall_driver       => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
          :db_name               => 'neutron',
          :db_user               => 'neutron',
          :db_password           => 'q_db_pass',
          :enable_dhcp_agent     => true,
          :enable_l3_agent       => true,
          :enable_metadata_agent => true,
          :auth_url              => 'http://127.0.0.1:35357/v2.0',
          :user_password         => 'q_pass',
          :shared_secret         => 'secret',
          :keystone_host         => '127.0.0.1',
          :enabled               => true,
          :enable_server         => true,
          :use_syslog            => false,
          :log_facility          => 'LOG_USER',
          :debug                 => true,
          :verbose               => true
        )

      end

    end

    context 'when nova network' do


      context 'when multi-host is not set' do
        let :params do
          default_params.merge(:neutron => false, :multi_host => false)
        end
        it {should contain_class('nova::network').with(
          :private_interface => 'eth0',
          :public_interface  => 'eth1',
          :fixed_range       => '10.0.0.0/24',
          :floating_range    => false,
          :network_manager   => 'nova.network.manager.FlatDHCPManager',
          :config_overrides  => {},
          :create_networks   => true,
          :num_networks      => 1,
          :enabled           => true,
          :install_service   => true
        )}
      end

      context 'when multi-host is set' do
        let :params do
          default_params.merge(:neutron => false, :multi_host => true)
        end
        it { should contain_nova_config('DEFAULT/multi_host').with(:value => true)}
        it {should contain_class('nova::network').with(
          :create_networks   => true,
          :enabled           => true,
          :install_service   => true
        )}
      end

    end
  end
end
