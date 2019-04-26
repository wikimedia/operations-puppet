class sudo::sudoersfile (
    String $package,
) {
    file { '/etc/sudoers':
        ensure  => present,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sudo/sudoers',
        require => Package[$package],
    }
}
