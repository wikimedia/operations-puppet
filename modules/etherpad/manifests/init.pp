# SPDX-License-Identifier: Apache-2.0
# Install and manage Etherpad Lite

class etherpad(
    String $etherpad_db_user,
    Stdlib::Fqdn $etherpad_db_host,
    String $etherpad_db_name,
    String $etherpad_db_pass,
    Stdlib::IP::Address $etherpad_ip        = '0.0.0.0',
    Stdlib::Port $etherpad_port             = 9001,
    Stdlib::Ensure::Service $service_ensure = 'running',
){
    ensure_packages('etherpad-lite')

    service { 'etherpad-lite':
        ensure    => $service_ensure,
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
