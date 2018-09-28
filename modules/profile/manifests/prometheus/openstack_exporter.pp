class profile::prometheus::openstack_exporter (
    $prometheus_nodes = hiera('profile::prometheus::prometheus_nodes'),
    $cpu_allocation_ratio = hiera('profile::prometheus::cpu_allocation_ratio'),
    $ram_allocation_ratio = hiera('profile::prometheus::ram_allocation_ratio'),
    $disk_allocation_ratio = hiera('profile::prometheus::disk_allocation_ratio'),
    $listen_port = hiera('profile::prometheus::listen_port'),
    $cache_refresh_interval = hiera('profile::prometheus::cache_refresh_interval'),
    $cache_file = hiera('profile::prometheus::cache_file'),
    $schedulable_instance_size = hiera('profile::prometheus::schedulable_instance_size'),
    $region = hiera('profile::prometheus::region'),
    $keystone_host = hiera('profile::prometheus::keystone_host'),
    $observer_password = hiera('profile::prometheus::observer_password'),
) {
    require_package('prometheus-openstack-exporter')

    file { '/etc/prometheus-openstack-exporter.yaml':
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/openstack-exporter.yaml.erb'),
    }

    service { 'prometheus-openstack-exporter':
        ensure  => running,
        require => File['/etc/prometheus-openstack-exporter.yaml'],
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'prometheus-openstack-exporter':
        proto  => 'tcp',
        port   => $listen_port,
        srange => "(@resolve((${prometheus_nodes_ferm})), @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
