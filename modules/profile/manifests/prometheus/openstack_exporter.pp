class profile::prometheus::openstack_exporter (
    Stdlib::Port $listen_port = lookup('profile::prometheus::openstack_exporter::listen_port', {default_value => 12345}),
    String[1]    $cloud       = lookup('profile::prometheus::openstack_exporter::cloud',       {default_value => 'eqiad1'}),
){
    # package only available on bullseye
    debian::codename::require::min('bullseye')

    apt::package_from_component { 'prometheus-openstack-exporter':
        component => 'component/prometheus-openstack-exporter',
        packages  => { 'prometheus-openstack-exporter' => 'present'}
    }

    $config_file = '/etc/prometheus-openstack-exporter.yaml'

    file { $config_file:
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/openstack-exporter.yaml.erb'),
    }

    file { '/usr/local/sbin/prometheus-openstack-exporter-wrapper':
        ensure => 'present',
        source => 'puppet:///modules/profile/prometheus/prometheus-openstack-exporter-wrapper.sh',
    }

    systemd::service { 'prometheus-openstack-exporter':
        ensure         => present,
        content        => systemd_template('prometheus-openstack-exporter'),
        restart        => true,
        override       => false,
        require        => File[$config_file],
        service_params => {
            ensure     => 'running',
        },
        subscribe      => [
            File[$config_file],
        ],
    }

    # TODO: delete after a few puppet runs
    file { '/var/cache/prometheus-openstack-exporter':
        ensure => absent,
    }
}
