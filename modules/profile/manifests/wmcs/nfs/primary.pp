class profile::wmcs::nfs::primary(
  $observer_pass = hiera('profile::openstack::eqiad1::observer_password'),
  $monitor_iface = hiera('profile::wmcs::nfs::primary::monitor_iface', 'eth0'),
  $data_iface    = hiera('profile::wmcs::nfs::primary::data_iface', 'eth1'),
) {
    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::observerenv

    class {'::labstore':
        nfsd_threads => '300',
    }

    package { [
            'python3-paramiko',
            'python3-pymysql',
        ]:
        ensure => present,
    }

    class {'labstore::backup_keys': }

    sysctl::parameters { 'cloudstore base':
        values   => {
            # Increase TCP max buffer size
            'net.core.rmem_max' => 67108864,
            'net.core.wmem_max' => 67108864,

            # Increase Linux auto-tuning TCP buffer limits
            # Values represent min, default, & max num. of bytes to use.
            'net.ipv4.tcp_rmem' => [ 4096, 87380, 33554432 ],
            'net.ipv4.tcp_wmem' => [ 4096, 65536, 33554432 ],
        },
        priority => 70,
    }

    class {'::labstore::fileserver::exports':
        server_vols   => ['project', 'home', 'tools-home', 'tools-project'],
    }

    # Enable RPS to balance IRQs over CPUs
    interface::rps { 'monitor':
        interface => $monitor_iface,
    }

    interface::manual{ 'data':
        interface => $data_iface,
    }

    if $::hostname == 'labstore1004' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'primary'

        # Do not change the 192 address here
        interface::ip { 'drbd-replication':
            interface => $data_iface,
            address   => '192.168.0.1',
            prefixlen => '30',
            require   => Interface::Manual['data'],
        }
    }

    if $::hostname == 'labstore1005' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'secondary'

        # Do not change the 192 address here
        interface::ip { 'drbd-replication':
            interface => $data_iface,
            address   => '192.168.0.2',
            prefixlen => '30',
            require   => Interface::Manual['data'],
        }
    }

    # TODO: hiera this
    # TODO: use hiera in maintain_dbusers too when this is hiera'd

    # Floating IP assigned to drbd primary(active NFS server). Should come from hiera
    $cluster_ip = '10.64.37.18'

    $subnet_gateway_ip = '10.64.37.1'

    $drbd_resource_config = {
        'test'   => {
            port       => '7790',
            device     => '/dev/drbd1',
            disk       => '/dev/misc/test',
            mount_path => '/srv/test',
        },
        'tools'  => {
            port       => '7791',
            device     => '/dev/drbd4',
            disk       => '/dev/tools/tools-project',
            mount_path => '/srv/tools',
        },
        'misc' => {
            port       => '7792',
            device     => '/dev/drbd3',
            disk       => '/dev/misc/misc-project',
            mount_path => '/srv/misc',
        },
    }

    $drbd_defaults = {
        'drbd_cluster' => {
            'labstore1004' => '192.168.0.1',
            'labstore1005' => '192.168.0.2',
        },
    }

    create_resources(labstore::drbd::resource, $drbd_resource_config, $drbd_defaults)

    Interface::Ip['drbd-replication'] -> Labstore::Drbd::Resource[keys($drbd_resource_config)]

    # state managed manually
    service { 'drbd':
        enable => false,
    }

    # state via nfs-manage
    if $::lsbdistcodename == 'stretch' {
        service { 'nfs-server':
            enable => false,
        }
    } else {
        service { 'nfs-kernel-server':
            enable => false,
        }
    }

    file { '/usr/local/sbin/nfs-manage':
        content => template('role/labs/nfs/nfs-manage.sh.erb'),
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
    }

    class {'labstore::monitoring::exports': }
    class {'labstore::monitoring::ldap': }
    class { 'labstore::monitoring::interfaces':
        monitor_iface => $monitor_iface,
    }

    class { 'labstore::monitoring::primary':
        drbd_role     => $drbd_role,
        cluster_iface => $monitor_iface,
        cluster_ip    => $cluster_ip,
    }

    file {'/usr/local/sbin/logcleanup':
        source => 'puppet:///modules/labstore/logcleanup.py',
        mode   => '0744',
        owner  => 'root',
        group  => 'root',
    }

    file {'/etc/logcleanup-config.yaml':
        source => 'puppet:///modules/profile/wmcs/nfs/primary/logcleanup-config.yaml',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/sbin/safe-du':
        source => 'puppet:///modules/labstore/monitor/safe-du.sh',
        mode   => '0744',
        owner  => 'root',
        group  => 'root',
    }

    sudo::user { 'diamond_dir_size_tracker':
        user       => 'diamond',
        privileges => ['ALL = NOPASSWD: /usr/local/sbin/safe-du'],
        require    => File['/usr/local/sbin/safe-du'],
    }

    if($drbd_role == 'primary') {

        class { 'profile::prometheus::node_directory_size':
            directory_size_paths => {
                'misc_home'     => { 'path' => '/exp/project/*/home', 'filter' => '*/tools/*' },
                'misc_project'  => { 'path' => '/exp/project/*/project', 'filter' => '*/tools/*' },
                'tools_home'    => { 'path' => '/exp/project/tools/home/*' },
                'tools_project' => { 'path' => '/exp/project/tools/project/*' },
                'paws'          => { 'path' => '/exp/project/tools/project/paws/userhomes/*' },
            },
        }
    }

    if($drbd_role != 'primary') {
        cron { 'logcleanup':
            ensure      => absent,
            environment => 'MAILTO=labs-admin@lists.wikimedia.org',
            command     => '/usr/local/sbin/logcleanup --config /etc/logcleanup-config.yaml',
            user        => 'root',
            minute      => '0',
            hour        => '14',
            require     => [File['/usr/local/sbin/logcleanup'], File['/etc/logcleanup-config.yaml']],
        }
    }
}
