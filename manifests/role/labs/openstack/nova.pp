class role::labs::openstack::nova::config {

    include role::labs::openstack::nova::config::eqiad
    include role::labs::openstack::nova::config::codfw

    $novaconfig = $::site ? {
        'eqiad' => $role::labs::openstack::nova::config::eqiad::novaconfig,
        'codfw' => $role::labs::openstack::nova::config::codfw::novaconfig,
    }
}

class role::labs::openstack::nova::config::common {

    require openstack
    include passwords::openstack::nova
    include passwords::openstack::ceilometer
    include passwords::labs::rabbitmq

    $commonnovaconfig = {
        db_name                    => 'nova',
        db_user                    => 'nova',
        db_pass                    => $passwords::openstack::nova::nova_db_pass,
        metadata_pass              => $passwords::openstack::nova::nova_metadata_pass,
        rabbit_user                => $passwords::labs::rabbitmq::rabbit_userid,
        rabbit_pass                => $passwords::labs::rabbitmq::rabbit_password,
        ceilometer_user            => $passwords::openstack::ceilometer::db_user,
        ceilometer_pass            => $passwords::openstack::ceilometer::db_pass,
        ceilometer_secret_key      => $passwords::openstack::ceilometer::secret_key,
        ceilometer_db_name         => 'ceilometer',
        my_ip                      => $::ipaddress_eth0,
        ldap_base_dn               => 'dc=wikimedia,dc=org',
        ldap_user_dn               => 'uid=novaadmin,ou=people,dc=wikimedia,dc=org',
        ldap_user_pass             => $passwords::openstack::nova::nova_ldap_user_pass,
        ldap_proxyagent            => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_proxyagent_pass       => $passwords::openstack::nova::nova_ldap_proxyagent_pass,
        controller_mysql_root_pass => $passwords::openstack::nova::controller_mysql_root_pass,
        puppet_db_name             => 'puppet',
        puppet_db_user             => 'puppet',
        puppet_db_pass             => $passwords::openstack::nova::nova_puppet_user_pass,
        # By default, don't allow projects to allocate public IPs; this way we can
        # let users have network admin rights, for firewall rules and such, and can
        # give them public ips by increasing their quota
        quota_floating_ips         => '0',
        libvirt_type               => 'kvm',
    }
}

class role::labs::openstack::nova::config::codfw inherits role::labs::openstack::nova::config::common {

    include role::labs::openstack::keystone::config::eqiad

    $nova_controller     = hiera('labs_nova_controller')
    $keystoneconfig      = $role::labs::openstack::keystone::config::eqiad::keystoneconfig
    $controller_hostname = $nova_controller
    $controller_address  = ipresolve($nova_controller, 4)
    $designate_hostname  = 'holmium.wikimedia.org'

    $codfwnovaconfig = {
        db_host                            => $controller_hostname,
        dhcp_domain                        => 'codfw.wmflabs',
        glance_host                        => $controller_hostname,
        rabbit_host                        => $controller_hostname,
        cc_host                            => $controller_hostname,
        designate_hostname                 => $designate_hostname,
        network_flat_interface             => 'eth1.1102',
        network_flat_tagged_base_interface => 'eth1',
        network_flat_interface_vlan        => '1102',
        flat_network_bridge                => 'br1102',
        network_public_interface           => 'eth0',
        network_host                       => hiera('labs_nova_network_ip'),
        api_host                           => hiera('labs_nova_api_host'),
        api_ip                             => ipresolve(hiera('labs_nova_api_host'),4),
        fixed_range                        => '10.68.16.0/21',
        dhcp_start                         => '10.68.16.4',
        network_public_ip                  => '208.80.155.255',
        dmz_cidr                           => '208.80.155.0/22,10.0.0.0/8',
        auth_uri                           => "http://${nova_controller}:5000",
        controller_hostname                => $controller_hostname,
        controller_address                 => $controller_address,
        ldap_host                          => $controller_hostname,
        puppet_host                        => $controller_hostname,
        puppet_db_host                     => $controller_hostname,
        live_migration_uri                 => 'qemu://%s.codfw.wmnet/system?pkipath=/var/lib/nova',
        zone                               => 'codfw',
        keystone_admin_token               => $keystoneconfig['admin_token'],
        keystone_auth_host                 => $keystoneconfig['bind_ip'],
        keystone_auth_protocol             => $keystoneconfig['auth_protocol'],
        keystone_auth_port                 => $keystoneconfig['auth_port'],
    }

    $novaconfig = merge( $codfwnovaconfig, $commonnovaconfig )
}

class role::labs::openstack::nova::config::eqiad inherits role::labs::openstack::nova::config::common {

    include role::labs::openstack::keystone::config::eqiad

    $nova_controller     = hiera('labs_nova_controller')
    $keystoneconfig      = $role::labs::openstack::keystone::config::eqiad::keystoneconfig
    $controller_hostname = $nova_controller
    $designate_hostname  ='holmium.wikimedia.org'
    $controller_address  = ipresolve($nova_controller,4)

    $eqiadnovaconfig = {
        db_host                            => 'm5-master.eqiad.wmnet',
        dhcp_domain                        => 'eqiad.wmflabs',
        glance_host                        => $controller_hostname,
        rabbit_host                        => $controller_hostname,
        cc_host                            => $controller_hostname,
        designate_hostname                 => $designate_hostname,
        network_flat_interface             => 'eth1.1102',
        network_flat_tagged_base_interface => 'eth1',
        network_flat_interface_vlan        => '1102',
        flat_network_bridge                => 'br1102',
        network_public_interface           => 'eth0',
        network_host                       => hiera('labs_nova_network_ip'),
        api_host                           => hiera('labs_nova_api_host'),
        api_ip                             => ipresolve(hiera('labs_nova_api_host'),4),
        fixed_range                        => '10.68.16.0/21',
        dhcp_start                         => '10.68.16.4',
        network_public_ip                  => '208.80.155.255',
        dmz_cidr                           => '208.80.155.0/22,10.0.0.0/8',
        auth_uri                           => "http://${nova_controller}:5000",
        controller_hostname                => $controller_hostname,
        controller_address                 => $controller_address,
        ldap_host                          => $controller_hostname,
        puppet_host                        => $controller_hostname,
        puppet_db_host                     => $controller_hostname,
        live_migration_uri                 => 'qemu://%s.eqiad.wmnet/system?pkipath=/var/lib/nova',
        zone                               => 'eqiad',
        keystone_admin_token               => $keystoneconfig['admin_token'],
        keystone_auth_host                 => $keystoneconfig['bind_ip'],
        keystone_auth_protocol             => $keystoneconfig['auth_protocol'],
        keystone_auth_port                 => $keystoneconfig['auth_port'],
    }

    if ( $::hostname == hiera('labs_nova_network_host') ) {
        $networkconfig = {
            network_flat_interface =>  'eth1.1102',
            network_flat_tagged_base_interface => 'eth1',
        }
        $novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig, $networkconfig )
    } else {
        $novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig )
    }
}

class role::labs::openstack::nova::common {

    include passwords::misc::scripts
    include role::labs::openstack::nova::config
    include role::labs::openstack::nova::wikiupdates

    $status_wiki_host_master = 'wikitech.wikimedia.org'
    $novaconfig              = $role::labs::openstack::nova::config::novaconfig

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

    include role::labs::openstack::nova::config
    include ::nutcracker::monitoring
    include ::mediawiki::packages::php5
    include ::mediawiki::cgroup
    include ::scap::scripts

    $novaconfig = $role::labs::openstack::nova::config::novaconfig

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
    include role::labs::openstack::nova::config
    include role::labs::puppetmaster
    include role::labs::openstack::keystone::config::eqiad
    include role::labs::openstack::glance::config::eqiad
    include role::labs::openstack::nova::wikiupdates
    include role::labs::openstack::nova::common

    $novaconfig = $role::labs::openstack::nova::config::novaconfig

    $glanceconfig = $::site ? {
        'eqiad' => $role::labs::openstack::glance::config::eqiad::glanceconfig,
    }
    $keystoneconfig = $::site ? {
        'eqiad' => $role::labs::openstack::keystone::config::eqiad::keystoneconfig,
    }

    class { '::openstack::nova::conductor':
        novaconfig        => $novaconfig,
    }
    class { '::openstack::nova::scheduler':
        novaconfig        => $novaconfig,
    }
    class { '::openstack::glance::service':
        glanceconfig      => $glanceconfig,
    }
    class { '::openstack::queue-server':
        novaconfig        => $novaconfig,
    }
    class { 'role::labs::openstack::keystone::server':
        glanceconfig => $glanceconfig,
    }

    class { '::openstack::controller_firewall': }

    class { '::openstack::adminscripts':
        novaconfig => $novaconfig
    }

    class { '::openstack::spreadcheck':
        novaconfig => $novaconfig
    }
}

class role::labs::openstack::nova::api {

    require openstack
    include role::labs::openstack::nova::config
    include role::labs::openstack::nova::common

    $novaconfig = $role::labs::openstack::nova::config::novaconfig

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
    include role::labs::openstack::nova::config
    include role::labs::openstack::nova::common
    include role::labs::openstack::nova::wikiupdates

    $novaconfig = $role::labs::openstack::nova::config::novaconfig

    $site_address = $::site ? {
        'eqiad' => '208.80.155.255',
    }

    interface::ip { 'openstack::network_service_public_dynamic_snat':
        interface => 'lo',
        address   => $site_address,
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
    include role::labs::openstack::nova::config
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::config::novaconfig

    ganglia::plugin::python {'diskstat': }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { '::openstack::nova::compute':
        novaconfig        => $novaconfig,
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

# global icinga hostgroups for virt/labs hosts
@monitoring::group { 'virt_eqiad': description => 'eqiad virt servers' }
@monitoring::group { 'virt_codfw': description => 'codfw virt servers' }
