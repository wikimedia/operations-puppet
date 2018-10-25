class profile::toolforge::services::bigbrother(
    $active_node = hiera('profile::toolforge::services::active_node'),
){
    file { '/usr/local/sbin/bigbrother':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        # File is named with .py suffix so that tox will run tests on it
        source => 'puppet:///modules/profile/toolforge/services/bigbrother.py',
    }

    systemd::service { 'bigbrother':
        ensure         => present,
        content        => systemd_template('bigbrother'),
        restart        => true,
        override       => false,
        require        => File['/usr/local/sbin/bigbrother'],
        service_params => {
            ensure     => ensure_service($::fqdn == $active_node),
        },
        subscribe      => [
            File['/usr/local/sbin/bigbrother'],
        ],
    }
}
