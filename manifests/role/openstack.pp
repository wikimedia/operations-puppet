# There should be only one of these, and it lives on the same
#  host as wikitech and OpenStackManager.
class role::labs_controller {
    # NOTE:  Every single one of these passwords needs to come from Private
    # before this class is used for anything.
    class { '::openstack::controller':
        public_address          => '10.64.20.4', # not really public!
        public_interface        => 'eth0',
        private_interface       => 'eth1',
        internal_address        => '10.64.20.4',
        floating_range          => '208.80.153.177/32',
        fixed_range             => '10.68.16.0/21',
        multi_host              => true,
        network_manager         => 'nova.network.manager.FlatDHCPManager',
        admin_email             => 'root@localhost',
        admin_password          => 'admin_password',
        cinder_db_password      => 'cinder_db_password',
        cinder_user_password    => 'cinder_user_password',
        keystone_admin_token    => 'keystone_admin_token',
        keystone_db_password    => 'keystone_db_password',
        glance_user_password    => 'glance_user_password',
        glance_db_password      => 'glance_db_password',
        nova_db_password        => 'nova_db_password',
        nova_user_password      => 'nova_user_password',
        rabbit_password         => 'rabbit_password',
        rabbit_user             => 'rabbit_user',
        secret_key              => '12345',
        neutron                 => false,
    }
}

# Only one of these, on a fast-networked misc server.  It's the
#  bottleneck for labs network traffic.
class role::labs_netnode {

}

# Many of these.  These are the boxes that actually host the labs VMs.
class role::labs_computenode {
    class { '::openstack::compute':
        private_interface  => 'eth1',
        internal_address   => $::ipaddress_eth0,
        libvirt_type       => 'kvm',
        fixed_range        => '10.68.16.0/21',
        network_manager    => 'nova.network.manager.FlatDHCPManager',
        multi_host         => true,
        rabbit_host        => '10.64.20.4',
        rabbit_password    => 'rabbit_password',
        cinder_db_password => 'cinder_db_password',
        glance_api_servers => '10.64.20.4:9292',
        nova_db_password   => 'nova_db_password',
        nova_user_password => 'nova_user_password',
        vnc_enabled        => false,
        manage_volumes     => true,
        neutron            => false,
    }
}

