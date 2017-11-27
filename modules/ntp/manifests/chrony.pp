# Set up an NTP time server based on Chrony. This is a simple setup
# which queries time data from an upstream NTP pool for dissemination
# in a local network
class ntp::chrony($pool, $permitted_networks=[]) {

    # Can be dropped once all ISC ntpd instances have been removed
    package { 'ntp':
        ensure => purged,
        before => Package['chrony'],
    }

    package { 'chrony':
        ensure => present,
    }

    file { 'chrony.conf':
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/chrony/chrony.conf',
        content => template('ntp/chrony-conf.erb'),
    }

    service { 'chrony':
        ensure    => running,
        require   => File['chrony.conf'],
        subscribe => File['chrony.conf'],
    }
}
