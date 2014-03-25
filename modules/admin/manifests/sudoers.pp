class admin::sudoers {
    file { '/etc/sudoers':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        tag     => 'sudoers',
    }
}
