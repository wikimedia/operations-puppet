# Install and manage Etherpad Lite

class etherpad {

    include passwords::etherpad_lite,
        etherpad::monitoring

    $etherpad_db_user = $passwords::etherpad_lite::etherpad_db_user
    $etherpad_db_host = $passwords::etherpad_lite::etherpad_db_host
    $etherpad_db_name = $passwords::etherpad_lite::etherpad_db_name
    $etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

    system::role { 'etherpad': description => 'Etherpad-lite server' }

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
}

