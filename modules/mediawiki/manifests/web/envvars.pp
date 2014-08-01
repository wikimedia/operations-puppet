class mediawiki::web::envvars {
    file_line { 'fix_apache_user':
        ensure  => present,
        path    => '/etc/apache2/envvars',
        line    => 'export APACHE_RUN_USER=apache',
        match   => 'export APACHE_RUN_USER=',
        require => Package['apache2'],
        before  => Service['apache2'],
    }

    file_line { 'fix_apache_group':
        ensure  => present,
        path    => '/etc/apache2/envvars',
        line    => 'export APACHE_RUN_GROUP=apache',
        match   => 'export APACHE_RUN_GROUP=',
        require => Package['apache2'],
        before  => Service['apache2'],
    }

    file { '/var/lock/apache2':
        ensure  => directory,
        owner   => 'apache',
        group   => 'root',
        mode    => '0755',
        before  => Service['apache2'],
    }

    if ubuntu_version('>= trusty') {
        apache::def{ 'HHVM': }
    }
}
