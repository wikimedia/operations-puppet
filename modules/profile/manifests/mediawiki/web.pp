# === Class mediawiki::web
#
# Installs and configures a web environment for mediawiki
class profile::mediawiki::web(
    $apache_mpm = hiera('profile::mediawiki::web::apache_mpm'),
    $workers_limit = hiera('profile::mediawiki::web::workers_limit', undef),
) {
    tag 'mediawiki', 'mw-apache-config'

    # AFAICS, we use www-data everywhere.
    $user = 'www-data'

    require ::profile::mediawiki::common
    class { '::apache::mpm':
        mpm => $apache_mpm
    }

    class { '::apache': }

    class { '::mediawiki::users':
        web => $user,
    }

    class { '::mediawiki::web::modules': }
    class { '::mediawiki::web::mpm_config':
        mpm           => $apache_mpm,
        workers_limit => $workers_limit
    }

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

    apache::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }
}
