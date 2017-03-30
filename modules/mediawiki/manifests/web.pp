# === Class mediawiki::web
#
# Installs and configures a web environment for mediawiki
class mediawiki::web {
    tag 'mediawiki', 'mw-apache-config'

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


    # Not needed anymore. TODO: remove at a later stage
    apache::def { 'HHVM':
        ensure => absent,
    }

    # Set the Server response header to be equal to the app server FQDN.
    include ::apache::mod::security2

    apache::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }
}
