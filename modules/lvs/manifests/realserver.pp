# lvs/realserver.pp

# Class: lvs::realserver
#
# Sets up a server to be used as a 'real server' by LVS
#
# Parameters:
#   - $realserver_ips
#       Array or hash (name => ip) of service IPs to answer on
class lvs::realserver($realserver_ips=[]) {

    file { '/etc/default/wikimedia-lvs-realserver':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("${module_name}/wikimedia-lvs-realserver.erb");
    }

    exec { '/usr/sbin/dpkg-reconfigure -p critical -f noninteractive wikimedia-lvs-realserver':
        require     => Package['wikimedia-lvs-realserver'],
        path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        subscribe   => File['/etc/default/wikimedia-lvs-realserver'],
        refreshonly => true;
    }

    package { 'wikimedia-lvs-realserver':
        ensure  => latest,
        require => File['/etc/default/wikimedia-lvs-realserver'];
    }
}
