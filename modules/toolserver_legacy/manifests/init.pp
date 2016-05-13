# Class: toolserver_legacy
#
# This class installs the parts needed for the Toolserver legacy
# "relic" server to provide redirection and mail aliases intended
# to serve the 'toolserver.org' domain.
#

class toolserver_legacy {
    include ::apache
    include ::apache::mod::rewrite

    $ssl_settings = ssl_ciphersuite('apache', 'compat')

    system::role { 'toolserver_legacy': description => 'Toolserver legacy server' }

    letsencrypt::cert::integrated { 'toolserver':
        subjects   => 'toolserver.org,www.toolserver.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    apache::site { 'www.toolserver.org':
        content => template('toolserver_legacy/www.toolserver.org.erb'),
        require => Sslcert::Certificate['toolserver.org'],
    }

    class { 'exim4':
        queuerunner => 'separate',
        config      => template('toolserver_legacy/exim4.conf.erb'),
    }

    file { '/var/www/html':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/var/www/html/index.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/toolserver_legacy/index.html',
        require => File['/var/www/html'],
    }

    file { '/var/www/html/notfound.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/toolserver_legacy/notfound.html',
        require => File['/var/www/html'],
    }
}

