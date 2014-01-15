# Install and manage Etherpad Lite

class etherpad {

    include passwords::etherpad_lite,
        etherpad::monitoring

    package { 'etherpad-lite':
        ensure => latest,
    }
    service { 'etherpad-lite':
        ensure    => running,
        require   => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
        enable    => true,
    }

    file { '/etc/etherpad-lite/settings.json':
        require => Package['etherpad-lite'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('etherpad/settings.json.erb'),
    }

    webserver::apache::site { 'etherpad.wikimedia.org':}
}

