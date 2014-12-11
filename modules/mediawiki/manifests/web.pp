class mediawiki::web {
    tag 'mediawiki', 'mw-apache-config'

    include ::apache
    include ::mediawiki
    include ::mediawiki::monitoring::webserver
    include ::mediawiki::web::modules
    include ::mediawiki::web::mpm_config


    file { '/etc/apache2/apache2.conf':
        source  => 'puppet:///modules/mediawiki/apache/apache2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    file { '/var/lock/apache2':
        ensure  => directory,
        owner   => 'apache',
        group   => 'root',
        mode    => '0755',
        before  => File['/etc/apache2/apache2.conf'],
    }

    apache::env { 'chuid_apache':
        vars => {
            'APACHE_RUN_USER'  => 'apache',
            'APACHE_RUN_GROUP' => 'apache',
        },
    }

    if os_version('ubuntu >= trusty') {
        apache::def { 'HHVM': }
    }
}
