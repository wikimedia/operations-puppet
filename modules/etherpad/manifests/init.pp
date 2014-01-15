# Install and manage Etherpad Lite

class etherpad {

    include passwords::etherpad_lite,
        etherpad::monitoring

    package { 'etherpad-lite':
        ensure => latest,
    }

    service { 'etherpad-lite':
        ensure    => running,
        renable   => true,
        equire    => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
    }

    file { '/etc/etherpad-lite/settings.json':
        require => Package['etherpad-lite'],
        content => template('etherpad/settings.json.erb'),
    }

    webserver::apache::site { 'etherpad.wikimedia.org':}
}

