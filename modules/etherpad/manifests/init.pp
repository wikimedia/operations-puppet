# Install and manage Etherpad Lite

class etherpad(
    $etherpad_host,
    $etherpad_ip,
    $etherpad_port,
    $etherpad_db_user,
    $etherpad_db_host,
    $etherpad_db_name,
    $etherpad_db_pass,
){

    package { 'etherpad-lite':
        ensure => latest,
    }

    service { 'etherpad-lite':
        ensure    => running,
        enable    => true,
        require   => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
    }

    file { '/etc/etherpad-lite/settings.json':
        require => Package['etherpad-lite'],
        content => template('etherpad/settings.json.erb'),
    }

    file { '/usr/share/etherpad-lite/src/static/robots.txt':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/etherpad/etherpad-robots.txt',
    }
}
