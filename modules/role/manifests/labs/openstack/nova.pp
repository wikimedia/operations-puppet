class role::labs::openstack::nova::common {

    include passwords::misc::scripts
    include role::labs::openstack::nova::wikiupdates

    $novaconfig                           = hiera_hash('novaconfig', {})
    $keystoneconfig                       = hiera_hash('keystoneconfig', {})

    $keystone_host                        = hiera('labs_keystone_host')
    $nova_controller                      = hiera('labs_nova_controller')
    $nova_api_host                        = hiera('labs_nova_api_host')
    $network_host                         = hiera('labs_nova_network_host')
    $status_wiki_host_master              = hiera('status_wiki_host_master')

    $novaconfig['bind_ip']                = ipresolve($keystone_host,4)
    $novaconfig['keystone_auth_host']     = $keystoneconfig['auth_host']
    $novaconfig['keystone_auth_port']     = $keystoneconfig['auth_port']
    $novaconfig['keystone_admin_token']   = $keystoneconfig['admin_token']
    $novaconfig['keystone_auth_protocol'] = $keystoneconfig['auth_protocol']

    $novaconfig['auth_uri']               = "http://${nova_controller}:5000"
    $novaconfig['api_ip']                 = ipresolve($nova_api_host,4)
    $novaconfig['controller_address']     = ipresolve($nova_controller,4)

    class { '::openstack::common':
        novaconfig                       => $novaconfig,
        instance_status_wiki_host        => $status_wiki_host_master,
        instance_status_wiki_domain      => 'labs',
        instance_status_wiki_page_prefix => 'Nova_Resource:',
        instance_status_wiki_region      => $::site,
        instance_status_dns_domain       => "${::site}.wmflabs",
        instance_status_wiki_user        => $passwords::misc::scripts::wikinotifier_user,
        instance_status_wiki_pass        => $passwords::misc::scripts::wikinotifier_pass,
    }
}

# This is the wikitech UI
class role::labs::openstack::nova::manager {

    requires_realm('production')

    include ::nutcracker::monitoring
    include ::mediawiki::packages::php5
    include ::mediawiki::cgroup
    include ::scap::scripts

    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    case $::realm {
        'production': {
            $certificate = 'wikitech.wikimedia.org'
        }
        default: {
            fail('unknown realm')
        }
    }

    sslcert::certificate { $certificate: }
    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http!${certificate}",
    }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    ferm::service { 'wikitech_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'wikitech_https':
        proto => 'tcp',
        port  => '443',
    }

    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    class { '::openstack::openstack-manager':
        novaconfig  => $novaconfig,
        certificate => $certificate,
    }

    # T89323
    monitoring::service { 'wikitech-static-sync':
        description   => 'are wikitech and wt-static in sync',
        check_command => 'check_wikitech_static',
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => {
            'memcached' => {
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                server_connections   => 2,
                servers              => [
                    '127.0.0.1:11000:1',
                ],
            },
        },
    }
}

# This is nova controller stuff
class role::labs::openstack::nova::controller {

    require openstack
    include ::openstack::controller_firewall

    include role::labs::puppetmaster
    include role::labs::openstack::nova::wikiupdates
    include role::labs::openstack::glance::server
    include role::labs::openstack::keystone::server

    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    class { '::openstack::nova::conductor':
        novaconfig => $novaconfig,
    }

    class { '::openstack::nova::scheduler':
        novaconfig => $novaconfig,
    }

    class { '::openstack::queue-server':
        novaconfig => $novaconfig,
    }

    class { '::openstack::adminscripts':
        novaconfig => $novaconfig
    }

    class { '::openstack::spreadcheck':
        novaconfig => $novaconfig
    }
}

class role::labs::openstack::nova::api {

    require openstack
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    class { '::openstack::nova::api':
        novaconfig        => $novaconfig,
    }
}

class role::labs::openstack::nova::network::bonding {
    interface::aggregate { 'bond1':
        orig_interface => 'eth1',
        members        => [ 'eth1', 'eth2', 'eth3' ],
    }
}

class role::labs::openstack::nova::network {

    require openstack
    include role::labs::openstack::nova::wikiupdates
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    interface::ip { 'openstack::network_service_public_dynamic_snat':
        interface => 'lo',
        address   => $novaconfig['site_address'],
    }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { '::openstack::nova::network':
        novaconfig        => $novaconfig,
    }
}

class role::labs::openstack::nova::wikiupdates {
    require openstack
    if ! defined(Package['python-mwclient']) {
        package { 'python-mwclient':
            ensure => latest,
        }
    }

    package { 'python-openstack-wikistatus':
        ensure  => installed,
        require => Package['python-mwclient'],
    }

    # Cleanup.  Can be removed by the time you are reading this.
    file { '/usr/local/lib/python2.6/dist-packages/wikinotifier.py':
        ensure => absent,
    }

    # Cleanup.  Can be removed by the time you are reading this.
    file { '/usr/local/lib/python2.7/dist-packages/wikinotifier.py':
        ensure => absent,
    }
}

class role::labs::openstack::nova::compute($instance_dev='/dev/md1') {

    system::role { 'role::labs::openstack::nova::compute':
        ensure      => 'present',
        description => 'openstack nova compute node',
    }

    require openstack
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig


    ganglia::plugin::python {'diskstat': }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { '::openstack::nova::compute':
        novaconfig => $novaconfig,
    }

    mount { '/var/lib/nova/instances':
        ensure  => mounted,
        device  => $instance_dev,
        fstype  => 'xfs',
        options => 'defaults',
    }

    file { '/var/lib/nova/instances':
        ensure  => directory,
        owner   => 'nova',
        group   => 'nova',
        require => Mount['/var/lib/nova/instances'],
    }

    if os_version('debian >= jessie || ubuntu >= trusty') {
        # Some older VMs have a hardcoded path to the emulator
        #  binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
        #  new distros don't create a kvm binary.  We can safely
        #  alias kvm to qemu-system-x86_64 which keeps those old
        #  instances happy.
        file { '/usr/bin/kvm':
            ensure => link,
            target => '/usr/bin/qemu-system-x86_64',
        }
    }
}
