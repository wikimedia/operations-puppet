# SPDX-License-Identifier: Apache-2.0
# Install and manage Etherpad Lite

class etherpad(
    $etherpad_db_user,
    $etherpad_db_host,
    $etherpad_db_name,
    $etherpad_db_pass,
    $etherpad_ip = '0.0.0.0',
    $etherpad_port = 9001,
){
    ensure_packages('etherpad-lite')

    service { 'etherpad-lite':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/etherpad-lite/settings.json'],
    }

    profile::auto_restarts::service { 'etherpad-lite':}

    file { '/etc/etherpad-lite/settings.json':
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
