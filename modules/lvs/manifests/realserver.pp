# lvs/realserver.pp

# Class: lvs::realserver
#
# Sets up a server to be used as a 'real server' by LVS
#
# @param realserver_ips
#       Array or hash (name => ip) of service IPs to answer on
class lvs::realserver (
    Variant[
        Array[Stdlib::IP::Address,1],
        Hash[String[1], Stdlib::IP::Address,1]
    ] $realserver_ips
) {

    package { 'wikimedia-lvs-realserver':
        ensure  => present,
        require => File['/etc/default/wikimedia-lvs-realserver'],
    }

    file { '/etc/default/wikimedia-lvs-realserver':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('lvs/wikimedia-lvs-realserver.erb'),
    }

    exec { '/usr/sbin/dpkg-reconfigure -p critical -f noninteractive wikimedia-lvs-realserver':
        path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        refreshonly => true,
        require     => Package['wikimedia-lvs-realserver'],
        subscribe   => File['/etc/default/wikimedia-lvs-realserver'],
    }
}
