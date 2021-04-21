class profile::wmcs::nfs::secondary_drbd(
    String $observer_pass = lookup('profile::openstack::eqiad1::observer_password'),
    Stdlib::IP::Address $cluster_ip = lookup('profile::wmcs::nfs::secondary::cluster_ip'),
    String $data_iface    = lookup('profile::wmcs::nfs::secondary::data_iface', {'default_value' => 'eno2'}),
    Hash[String, Hash[String, Variant[Integer,String]]] $drbd_resource_config = lookup('profile::wmcs::nfs::secondary::drbd_resource_config'),
    Hash[String, Stdlib::IP::Address::V4] $drbd_cluster = lookup('profile::wmcs::nfs::secondary::drbd_cluster'),
    Stdlib::Fqdn $standby_server     = lookup('profile::wmcs::nfs::secondary::standby'),
    Array[Stdlib::Host] $secondary_servers = lookup('secondary_nfs_servers'),
) {
    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::observerenv

    $monitor_iface = $facts['networking']['primary']
    class {'::labstore':
        nfsd_threads => 192,
    }

    ensure_packages([
        'python3-paramiko',
        'python3-pymysql',
        'python3-dateutil',
    ])

    $drbd_expected_role = $facts['fqdn'] ? {
        $standby_server => 'secondary',
        default         => 'primary',
    }

    # Determine the actual role from a custom fact.
    if has_key($facts, 'drbd_role') {
        if $facts['drbd_role'].values().unique().length() > 1 {
            $drbd_actual_role = 'inconsistent'
        } else {
            $drbd_actual_role = $facts['drbd_role'].values().unique()[0]
        }
    } else {
        $drbd_actual_role = undef
    }

    $drbd_ip_address = $drbd_cluster[$facts['hostname']]

    # Make sure the mountpoints are there
    file{'/srv/test':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0777',
    }

    file{'/srv/tools':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file{'/srv/misc':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file{'/srv/scratch':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    # Enable RPS to balance IRQs over CPUs
    # This breaks the puppet compiler, so re-enable after testing compiles
    # interface::rps { 'monitor':
    #     interface => $monitor_iface,
    # }

    $drbd_defaults = {
        'drbd_cluster' => $drbd_cluster
    }

    interface::manual{ 'data':
        interface => $data_iface,
    }

    interface::ip { 'drbd-replication':
        interface => $data_iface,
        address   => $drbd_ip_address,
        prefixlen => '30',
        require   => Interface::Manual['data'],
    }

    create_resources(labstore::drbd::resource, $drbd_resource_config, $drbd_defaults)

    Interface::Ip['drbd-replication'] -> Labstore::Drbd::Resource[keys($drbd_resource_config)]
    $cluster_ips_ferm = join($drbd_cluster.values(), ' ')
    $drbd_resource_config.each |String $volume, Hash $volume_config| {
        ferm::service { "drbd-${volume}":
            proto  => 'tcp',
            port   => $volume_config['port'],
            srange => "(${cluster_ips_ferm})",
        }
    }

    # state managed manually
    service { 'drbd':
        enable => false,
    }
    service { 'nfs-server':
        enable => false,
    }
    $nfs_start_command = 'systemctl start nfs-server'
    $nfs_stop_command = 'systemctl stop nfs-server'

    file { '/usr/local/sbin/nfs-manage':
        content => template('profile/wmcs/nfs/nfs-manage.sh.erb'),
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
    }

    class {'labstore::monitoring::exports':
        drbd_role => $drbd_actual_role,
    }
    class {'labstore::monitoring::volumes':
        server_vols => [
            '/srv/tools',
            '/srv/misc'
        ],
        drbd_role   => $drbd_actual_role,
    }

    class {'labstore::fileserver::exports':
        server_vols   => ['maps'],
    }
    class {'labstore::monitoring::exports': }
    class {'labstore::monitoring::ldap': }
    class {'labstore::monitoring::volumes':
        server_vols => [
            '/srv/scratch',
            '/srv/maps'
        ],
    }
    class { 'labstore::monitoring::interfaces':
        monitor_iface       => $monitor_iface,
        int_throughput_warn => 937500000,  # 7500Mbps
        int_throughput_crit => 1062500000, # 8500Mbps
    }

    $secondary_servers_ferm = join($secondary_servers, ' ')
    ferm::service { 'labstore_nfs_monitor':
        proto  => 'tcp',
        port   => '2049',
        srange => "(@resolve((${secondary_servers_ferm})) @resolve((${secondary_servers_ferm}), AAAA))",
    }

    nrpe::monitor_service { 'check_nfs_status':
        description   => 'NFS port is open on cluster IP',
        nrpe_command  => "/usr/lib/nagios/plugins/check_tcp -H ${cluster_ip} -p 2049 --timeout=2",
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
