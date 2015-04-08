# == Class: jetty::service
#
# Defines a Java service
#
define jetty::service(
    $war,
    $port,
    $user = 'nobody',
    $log_channel = undef,
    $memory_limit = '64M',
    $java_options = '',
) {
    include ::jetty

    $log = $log_channel ? {
        undef => $name,
        default => $log_channel,
    }

    file { "/etc/init/$name.conf":
        ensure => present,
        content => template( 'jetty/service.conf.erb' ),
        owner => 'root',
        group => 'root',
        mode  => '0444',
        notify => Service[$name],
    }

    service { $name:
        ensure => 'running',
        provider => 'upstart',
        #subscribe => Class['jetty'],
    }
}