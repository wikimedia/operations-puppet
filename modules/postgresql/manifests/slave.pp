# Class: postgresql::slave
#
# This class installs the server in a slave configuration
# It will create the replication user
#
# Parameters:
#   master_server
#       The FQDN of the master server to connect to
#   replication_pass
#       The password the replication user should use
#   pgversion
#       Defaults to 9.1. Valid values 8.4, 9.1 in Ubuntu
#   ensure
#       Defaults to present
#
# Actions:
#  Install/configure postgresql in a slave configuration
#
# Requires:
#
# Sample Usage:
#  class {'postgresql::slave':
#       master_server => 'mserver',
#       replication_pass => 'mypass',
#  }
#
class postgresql::slave(
                        $master_server,
                        $replication_pass,
                        $includes=[],
                        $pgversion='9.1',
                        $ensure='present',
                    ) {

    class { 'postgresql::server':
        pgversion => $pgversion,
        ensure    => $ensure,
        includes  => [ $includes, 'slave.conf'],
    }

    if $::ipaddress {
        @@postgresql::user { "replication@${master_server}-${::fqdn}_v4":
            ensure   => 'present',
            user     => 'replication',
            password => $replication_pass,
            cidr     => "$::ipaddress/32",
            type     => 'host',
            method   => 'md5',
            database => 'replication',
            attrs    => 'REPLICATION',
            tag      => $master_server,
        }
    }
    if $::ipaddress6 {
        @@postgresql::user { "replication@${master_server}-${::fqdn}_v6":
            ensure   => 'present',
            user     => 'replication',
            password => $replication_pass,
            cidr     => "$::ipaddress6/128",
            type     => 'host',
            method   => 'md5',
            database => 'replication',
            attrs    => 'REPLICATION',
            tag      => $master_server,
        }
    }

    file { "/etc/postgresql/${pgversion}/main/slave.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/postgresql/slave.conf',
        require => Class['postgresql::server'],
    }

    file { "/var/lib/postgresql/${pgversion}/main/recovery.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/recovery.conf.erb'),
        require => Class['postgresql::server'],
    }

    # Let's sync once all our content from the master
    if $ensure == 'present' {
        exec { "pg_basebackup-${master_server}":
            environment => "PGPASSWORD=${replication_pass}",
            command     => "/usr/bin/pg_basebackup -D /var/lib/postgresql/${pgversion}/main -h ${master_server} -U replication -w",
            user        => 'postgres',
            unless      => "/usr/bin/test -f /var/lib/postgresql/${pgversion}/main/PG_VERSION",
            require     => Class['postgresql::server'],
        }
    }
}
