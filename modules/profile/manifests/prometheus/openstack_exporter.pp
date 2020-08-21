class profile::prometheus::openstack_exporter (
    Array[Stdlib::Host] $prometheus_nodes       = lookup('prometheus_nodes'),
    Float               $cpu_allocation_ratio   = lookup('profile::prometheus::cpu_allocation_ratio'),
    Float               $ram_allocation_ratio   = lookup('profile::prometheus::ram_allocation_ratio'),
    Float               $disk_allocation_ratio  = lookup('profile::prometheus::disk_allocation_ratio'),
    Stdlib::Port        $listen_port            = lookup('profile::prometheus::listen_port'),
    Integer             $cache_refresh_interval = lookup('profile::prometheus::cache_refresh_interval'),
    Stdlib::Unixpath    $cache_file             = lookup('profile::prometheus::cache_file'),
    Integer             $sched_ram_mbs          = lookup('profile::prometheus::sched_ram_mbs'),
    Integer             $sched_vcpu             = lookup('profile::prometheus::sched_vcpu'),
    Integer             $sched_disk_gbs         = lookup('profile::prometheus::sched_disk_gbs'),
    String              $region                 = lookup('profile::prometheus::region'),
    String              $observer_password      = lookup('profile::prometheus::observer_password'),
){

    require_package('prometheus-openstack-exporter')

    file { '/etc/prometheus-openstack-exporter.yaml':
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/openstack-exporter.yaml.erb'),
    }

    file { '/usr/local/sbin/prometheus-openstack-exporter-wrapper':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0554',
        source  => 'puppet:///modules/profile/prometheus/prometheus-openstack-exporter-wrapper.sh',
        require => File['/etc/prometheus-openstack-exporter.yaml'],
    }

    systemd::service { 'prometheus-openstack-exporter':
        ensure         => present,
        content        => systemd_template('prometheus-openstack-exporter'),
        restart        => true,
        override       => false,
        require        => File['/usr/local/sbin/prometheus-openstack-exporter-wrapper'],
        service_params => {
            ensure     => 'running',
        },
        subscribe      => [
            File['/etc/prometheus-openstack-exporter.yaml'],
            File['/usr/local/sbin/prometheus-openstack-exporter-wrapper'],
        ],
    }

    # perhaps this should go in the package
    file { '/var/cache/prometheus-openstack-exporter':
        ensure => directory,
        force  => true,
        mode   => '0775',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $prometheus_ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    ferm::service { 'prometheus-openstack-exporter':
        proto  => 'tcp',
        port   => $listen_port,
        srange => $prometheus_ferm_srange,
    }
}
