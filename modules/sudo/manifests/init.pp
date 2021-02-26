class sudo {
    package { 'sudo':
        ensure => installed,
    }

    file { '/etc/sudoers':
        ensure       => present,
        mode         => '0440',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/sudo/sudoers',
        require      => Package[sudo],
        validate_cmd => '/usr/sbin/visudo -c -f %'
    }
}
