# === Class mediawiki::web
#
# Installs and configures a web environment for mediawiki
class mediawiki::web {
    tag 'mediawiki', 'mw-apache-config'

    requires_os('ubuntu >= trusty || Debian >= jessie')
    include ::apache
    include ::mediawiki
    include ::mediawiki::users

    include ::mediawiki::web::modules
    include ::mediawiki::web::mpm_config


    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    file { '/var/lock/apache2':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'root',
        mode   => '0755',
        before => File['/etc/apache2/apache2.conf'],
    }

    apache::env { 'chuid_apache':
        vars => {
            'APACHE_RUN_USER'  => $::mediawiki::users::web,
            'APACHE_RUN_GROUP' => $::mediawiki::users::web,
        },
    }

    apache::def { 'HHVM': }
}
