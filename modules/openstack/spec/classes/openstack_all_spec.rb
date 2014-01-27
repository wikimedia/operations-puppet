require 'spec_helper'

describe 'openstack::all' do

  # minimum set of default parameters
  let :params do
    {
      :public_address        => '10.0.0.1',
      :public_interface      => 'eth0',
      :admin_email           => 'some_user@some_fake_email_address.foo',
      :admin_password        => 'ChangeMe',
      :rabbit_password       => 'rabbit_pw',
      :keystone_db_password  => 'keystone_pass',
      :keystone_admin_token  => 'keystone_admin_token',
      :glance_db_password    => 'glance_pass',
      :glance_user_password  => 'glance_pass',
      :nova_db_password      => 'nova_pass',
      :nova_user_password    => 'nova_pass',
      :secret_key            => 'secret_key',
      :mysql_root_password   => 'sql_pass',
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
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end

  context 'neutron enabled (which is the default)' do
    before do
      params.merge!(:cinder => false)
    end

    it 'raises an error if no neutron_user_password is set' do
      expect { subject }.to raise_error(Puppet::Error, /neutron_user_password must be specified when neutron is configured/)
    end

    context 'with neutron_user_password set' do
      before do
        params.merge!(:neutron_user_password => 'neutron_user_password')
      end
      it 'raises an error if no neutron_db_password is set' do
        expect { subject }.to raise_error(Puppet::Error, /neutron_db_password must be set when configuring neutron/)
      end
    end

    context 'with neutron_user_password and neutron_db_password set' do
      before do
        params.merge!(
          :neutron_user_password => 'neutron_user_password',
          :neutron_db_password => 'neutron_db_password'
        )
      end
      it 'raises an error if no bridge_interface is set' do
        expect { subject }.to raise_error(Puppet::Error, /bridge_interface must be set when configuring neutron/)
      end
    end

    context 'with neutron_user_password, neutron_db_password, and bridge_interface set' do
      before do
        params.merge!(
          :neutron_user_password => 'neutron_user_password',
          :neutron_db_password   => 'neutron_db_password',
          :bridge_interface      => 'eth0'
        )
      end
    end

    context 'with neutron_user_password, neutron_db_password, bridge_interface, and ovs_local_ip set' do
      before do
        params.merge!(
          :neutron_user_password => 'neutron_user_password',
          :neutron_db_password   => 'neutron_db_password',
          :bridge_interface      => 'eth0',
          :ovs_enable_tunneling  => true,
          :ovs_local_ip          => '10.0.1.1'
        )
      end
      it 'raises an error if no shared metadata key is set' do
        expect { subject }.to raise_error(Puppet::Error, /metadata_shared_secret parameter must be set when using metadata agent/)
      end
    end

    context 'with neutron_user_password, neutron_db_password, bridge_interface, ovs_local_ip, and shared_secret set' do
      before do
        params.merge!(
          :neutron_user_password => 'neutron_user_password',
          :neutron_db_password   => 'neutron_db_password',
          :bridge_interface      => 'eth0',
          :ovs_enable_tunneling  => true,
          :ovs_local_ip          => '10.0.1.1',
          :metadata_shared_secret => 'shared_md_secret'
        )
      end
      it 'contains an openstack::neutron class' do
        should contain_class('openstack::neutron').with(
          :db_host             => '127.0.0.1',
          :rabbit_host         => '127.0.0.1',
          :rabbit_user         => 'openstack',
          :rabbit_password     => 'rabbit_pw',
          :rabbit_virtual_host => '/',
          :ovs_enable_tunneling => true,
          :ovs_local_ip        => '10.0.1.1',
          :bridge_uplinks      => 'br-ex:eth0',
          :bridge_mappings     => 'default:br-ex',
          :enable_ovs_agent    => true,
          :firewall_driver     => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
          :db_name             => 'neutron',
          :db_user             => 'neutron',
          :db_password         => 'neutron_db_password',
          :enable_dhcp_agent   => true,
          :enable_l3_agent     => true,
          :enable_metadata_agent => true,
          :auth_url            => 'http://127.0.0.1:35357/v2.0',
          :user_password       => 'neutron_user_password',
          :shared_secret       => 'shared_md_secret',
          :keystone_host       => '127.0.0.1',
          :enabled             => true,
          :enable_server       => true,
          :debug               => false,
          :verbose             => false
        )
      end
    end

    context 'with neutron_user_password, neutron_db_password, bridge_interface, ovs_local_ip, metadata_shared_secret, and force_config_drive set' do
      before do
        params.merge!(
          :neutron_user_password  => 'neutron_user_password',
          :neutron_db_password    => 'neutron_db_password',
          :bridge_interface       => 'eth0',
          :ovs_enable_tunneling   => true,
          :ovs_local_ip           => '10.0.1.1',
          :metadata_shared_secret => 'shared_md_secret',
          :force_config_drive     => true
        )
      end
      it 'contains a nova::compute class with force_config_drive set' do
        should contain_class('nova::compute').with(
          :enabled                => true,
          :force_config_drive     => true
        )
      end
    end

    context 'with neutron_user_password, neutron_db_password, bridge_interface, ovs_local_ip, bridge_mappings, bridge_uplinks, and shared_secret set' do
      before do
        params.merge!(
          :neutron_user_password => 'neutron_user_password',
          :neutron_db_password   => 'neutron_db_password',
          :bridge_interface      => 'eth0',
          :ovs_enable_tunneling  => true,
          :ovs_local_ip          => '10.0.1.1',
          :network_vlan_ranges => '1:1000',
          :bridge_mappings     => ['intranet:br-intra','extranet:br-extra'],
          :bridge_uplinks      => ['intranet:eth1','extranet:eth2'],
          :tenant_network_type => 'vlan',
          :metadata_shared_secret => 'shared_md_secret'
        )
      end
      it 'contains an openstack::neutron class' do
        should contain_class('openstack::neutron').with(
          :db_host             => '127.0.0.1',
          :rabbit_host         => '127.0.0.1',
          :rabbit_user         => 'openstack',
          :rabbit_password     => 'rabbit_pw',
          :rabbit_virtual_host => '/',
          :ovs_enable_tunneling => true,
          :ovs_local_ip        => '10.0.1.1',
          :network_vlan_ranges => '1:1000',
          :bridge_uplinks      => ['intranet:eth1','extranet:eth2'],
          :bridge_mappings     => ['intranet:br-intra','extranet:br-extra'],
          :tenant_network_type => 'vlan',
          :enable_ovs_agent    => true,
          :firewall_driver     => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
          :db_name             => 'neutron',
          :db_user             => 'neutron',
          :db_password         => 'neutron_db_password',
          :enable_dhcp_agent   => true,
          :enable_l3_agent     => true,
          :enable_metadata_agent => true,
          :auth_url            => 'http://127.0.0.1:35357/v2.0',
          :user_password       => 'neutron_user_password',
          :shared_secret       => 'shared_md_secret',
          :keystone_host       => '127.0.0.1',
          :enabled             => true,
          :enable_server       => true,
          :debug               => false,
          :verbose             => false
        )
      end
    end
  end

  context 'cinder enabled (which is the default)' do
    before do
      params.merge!(
        :neutron_user_password => 'neutron_user_password',
        :neutron_db_password   => 'neutron_db_password',
        :bridge_interface      => 'eth0',
        :ovs_enable_tunneling  => true,
        :ovs_local_ip          => '10.0.1.1',
        :metadata_shared_secret => 'shared_md_secret'
      )
    end

    it 'raises an error if no cinder_db_password is set' do
      expect { subject }.to raise_error(Puppet::Error, /Must set cinder db password when setting up a cinder controller/)
    end

    context 'with cinder_db_password set' do
      before do
        params.merge!(:cinder_db_password => 'cinder_db_password')
      end
      it 'raises an error if no cinder_user_password is set' do
        expect { subject }.to raise_error(Puppet::Error, /Must set cinder user password when setting up a cinder controller/)
      end
    end

    context 'with cinder_db_password and cinder_user_password set' do
      before do
        params.merge!(
          :cinder_db_password => 'cinder_db_password',
          :cinder_user_password => 'cinder_user_password'
        )
      end
      it 'raises an error if no cinder_user_password is set' do
        should contain_class('openstack::cinder::all').with(
          :bind_host          => '0.0.0.0',
          :keystone_auth_host => '127.0.0.1',
          :keystone_password  => 'cinder_user_password',
          :rabbit_userid      => 'openstack',
          :rabbit_host        => '127.0.0.1',
          :db_password        => 'cinder_db_password',
          :db_dbname          => 'cinder',
          :db_user            => 'cinder',
          :db_type            => 'mysql',
          :iscsi_ip_address   => '127.0.0.1',
          :setup_test_volume  => false,
          :manage_volumes     => true,
          :volume_group       => 'cinder-volumes',
          :debug              => false,
          :verbose            => false
        )
        should contain_nova_config('DEFAULT/volume_api_class').with(:value => 'nova.volume.cinder.API')
      end
    end
  end

  context 'cinder enabled and Ceph RBD as the backend' do
    before do
      params.merge!(
        :neutron_user_password  => 'neutron_user_password',
        :neutron_db_password    => 'neutron_db_password',
        :bridge_interface       => 'eth0',
        :ovs_enable_tunneling   => true,
        :ovs_local_ip           => '10.0.1.1',
        :metadata_shared_secret => 'shared_md_secret',
        :cinder_db_password     => 'cinder_db_password',
        :cinder_user_password   => 'cinder_user_password',
        :cinder_volume_driver   => 'rbd',
        :cinder_rbd_secret_uuid => 'e80afa94-a64c-486c-9e34-d55e85f26406'
      )
    end

    it 'should have cinder::volume::rbd' do
      should contain_class('cinder::volume::rbd').with(
        :rbd_pool        => 'volumes',
        :rbd_user        => 'volumes',
        :rbd_secret_uuid => 'e80afa94-a64c-486c-9e34-d55e85f26406'
      )
    end
  end

  context 'cinder and neutron enabled (which is the default)' do
    before do
      params.merge!(
        :neutron_user_password  => 'neutron_user_password',
        :neutron_db_password    => 'neutron_db_password',
        :bridge_interface       => 'eth0',
        :ovs_enable_tunneling   => true,
        :ovs_local_ip           => '10.0.1.1',
        :metadata_shared_secret => 'shared_md_secret',
        :cinder_db_password     => 'cinder_db_password',
        :cinder_user_password   => 'cinder_user_password'
      )
    end

    it 'should have openstack::db::mysql configured' do
      should contain_class('openstack::db::mysql').with(
        :charset                => 'latin1',
        :mysql_root_password    => 'sql_pass',
        :mysql_bind_address     => '0.0.0.0',
        :mysql_account_security => true,
        :keystone_db_user       => 'keystone',
        :keystone_db_password   => 'keystone_pass',
        :keystone_db_dbname     => 'keystone',
        :glance_db_user         => 'glance',
        :glance_db_password     => 'glance_pass',
        :glance_db_dbname       => 'glance',
        :nova_db_user           => 'nova',
        :nova_db_password       => 'nova_pass',
        :nova_db_dbname         => 'nova',
        :cinder                 => true,
        :cinder_db_user         => 'cinder',
        :cinder_db_password     => 'cinder_db_password',
        :cinder_db_dbname       => 'cinder',
        :neutron                => true,
        :neutron_db_user        => 'neutron',
        :neutron_db_password    => 'neutron_db_password',
        :neutron_db_dbname      => 'neutron',
        :allowed_hosts          => '%',
        :enabled                => true
      )
    end

    it 'should have openstack::keystone configured' do
      should contain_class('openstack::keystone').with(
        :debug                 => false,
        :verbose               => false,
        :db_type               => 'mysql',
        :db_host               => '127.0.0.1',
        :db_password           => 'keystone_pass',
        :db_name               => 'keystone',
        :db_user               => 'keystone',
        :admin_token           => 'keystone_admin_token',
        :admin_tenant          => 'admin',
        :admin_email           => 'some_user@some_fake_email_address.foo',
        :admin_password        => 'ChangeMe',
        :public_address        => '10.0.0.1',
        :internal_address      => '10.0.0.1',
        :admin_address         => '10.0.0.1',
        :region                => 'RegionOne',
        :glance_user_password  => 'glance_pass',
        :nova_user_password    => 'nova_pass',
        :cinder                => true,
        :cinder_user_password  => 'cinder_user_password',
        :neutron               => true,
        :neutron_user_password => 'neutron_user_password',
        :enabled               => true,
        :bind_host             => '0.0.0.0'
      )
    end

    it 'should have openstack::glance configured' do
      should contain_class('openstack::glance').with(
        :debug                 => false,
        :verbose               => false,
        :db_type               => 'mysql',
        :db_host               => '127.0.0.1',
        :keystone_host         => '127.0.0.1',
        :db_user               => 'glance',
        :db_name               => 'glance',
        :db_password           => 'glance_pass',
        :user_password         => 'glance_pass',
        :backend               => 'file',
        :enabled               => true
      )
    end

    it 'should have nova::compute configured' do
      should contain_class('nova::compute').with(
        :enabled               => true,
        :vnc_enabled           => true,
        :vncserver_proxyclient_address => '10.0.0.1',
        :vncproxy_host         => '10.0.0.1'
      )
    end

    it 'should have nova::compute::libvirt configured' do
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type          => 'kvm',
        :vncserver_listen      => '10.0.0.1',
        :migration_support     => false
      )
    end

    it 'should have openstack::nova::controller configured' do
      should contain_class('openstack::nova::controller').with(
        :db_host                 => '127.0.0.1',
        :network_manager         => 'nova.network.manager.FlatDHCPManager',
        :network_config          => {},
        :floating_range          => false,
        :fixed_range             => '10.0.0.0/24',
        :public_address          => '10.0.0.1',
        :admin_address           => false,
        :internal_address        => '10.0.0.1',
        :auto_assign_floating_ip => false,
        :create_networks         => true,
        :num_networks            => 1,
        :multi_host              => false,
        :public_interface        => 'eth0',
        :private_interface       => false,
        :neutron                 => true,
        :neutron_user_password   => 'neutron_user_password',
        :metadata_shared_secret  => 'shared_md_secret',
        :nova_admin_tenant_name  => 'services',
        :nova_admin_user         => 'nova',
        :nova_user_password      => 'nova_pass',
        :nova_db_password        => 'nova_pass',
        :nova_db_user            => 'nova',
        :nova_db_dbname          => 'nova',
        :enabled_apis            => 'ec2,osapi_compute,metadata',
        :rabbit_user             => 'openstack',
        :rabbit_password         => 'rabbit_pw',
        :rabbit_virtual_host     => '/',
        :glance_api_servers      => '10.0.0.1:9292',
        :vnc_enabled             => true,
        :vncproxy_host           => '10.0.0.1',
        :debug                   => false,
        :verbose                 => false,
        :enabled                 => true
      )
    end

    it 'should configure horizon' do
      should contain_class('openstack::horizon').with(
        :secret_key      => 'secret_key',
        :cache_server_ip => '127.0.0.1',
        :cache_server_port => 11211,
        :horizon_app_links => ''
      )
    end
  end

  context 'without neutron' do
    before do
      params.merge!(
        :cinder => false,
        :neutron => false,
        :private_interface => 'eth1')
    end

    context 'without fixed_range' do
      before do
        params.merge!(
          :fixed_range => false
        )
      end
      it 'raises an error if no fixed_range is given' do
        expect { subject }.to raise_error(Puppet::Error, /Must specify the fixed range when using nova-network/)
      end
    end

    context 'without private_interface' do
      before do
        params.merge!(:private_interface  => false)
      end
      it 'raises an error if no private_interface is given' do
        expect { subject }.to raise_error(Puppet::Error, /private interface must be set when nova networking is used/)
      end
    end

    context 'with multi_host enabled' do
      before do
        params.merge!(
          :multi_host => true
        )
      end

      it 'sets send_arp_for_ha' do
        should contain_nova_config('DEFAULT/send_arp_for_ha').with(:value => true)
      end


    end

    context 'with multi_host disabled' do
      before do
        params.merge!(
          :multi_host => false
        )
      end

      it 'unsets multi_host and send_arp_for_ha' do
        should contain_nova_config('DEFAULT/multi_host').with(:value => false)
        should contain_nova_config('DEFAULT/send_arp_for_ha').with(:value => false)
      end
    end

    it 'configures nova::network' do
      should contain_class('nova::network').with(
        :private_interface => 'eth1',
        :public_interface  => 'eth0',
        :fixed_range       => '10.0.0.0/24',
        :floating_range    => false,
        :network_manager   => 'nova.network.manager.FlatDHCPManager',
        :config_overrides  => {},
        :create_networks   => true,
        :enabled           => true,
        :install_service   => true
      )
    end
  end

  context 'glance enabled and rbd as the backend' do
    before do
      params.merge!(
        :neutron_user_password  => 'neutron_user_password',
        :neutron_db_password    => 'neutron_db_password',
        :bridge_interface       => 'eth0',
        :ovs_enable_tunneling   => true,
        :ovs_local_ip           => '10.0.1.1',
        :metadata_shared_secret => 'shared_md_secret',
        :cinder_db_password     => 'cinder_db_password',
        :cinder_user_password   => 'cinder_user_password',
        :glance_backend         => 'rbd'
      )
    end

    it 'should have glance::backend::rbd with default user/pool' do
      should contain_class('glance::backend::rbd').with(
        :rbd_store_user   => 'images',
        :rbd_store_pool   => 'images'
      )
    end
  end
end
