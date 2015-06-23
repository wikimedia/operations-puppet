# Class: role::relic
#
# This class installs the parts needed for the Toolserver legacy
# "relic" server to provide redirection and mail aliases intended
# to server the 'toolserver.org' domain.
#

class role::relic {
    include ::apache
    include ::apache::mod::rewrite

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    system::role { 'relic': description => 'Toolserver legacy server' }

    sslcert::certificate { 'toolserver.org':
        source => 'puppet:///files/ssl/toolserver.org.crt',
    }

    apache::site { 'www.toolserver.org':
        content => template('apache/sites/www.toolserver.org.erb'),
        require => Sslcert::Certificate['toolserver.org'],
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
        source  => 'puppet:///files/misc/relic/index.html',
        require => File['/var/www/html'],
    }

    file { '/var/www/html/notfound.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/misc/relic/notfound.html',
        require => File['/var/www/html'],
    }
}

