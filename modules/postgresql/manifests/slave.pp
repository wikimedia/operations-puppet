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
    $datadir=undef
    ) {

    class { 'postgresql::server':
        pgversion => $pgversion,
        ensure    => $ensure,
        includes  => [ $includes, 'slave.conf'],
        datadir   => $datadir,
    }

    file { "/etc/postgresql/${pgversion}/main/slave.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/postgresql/slave.conf',
        require => Class['postgresql::server'],
    }

    if $datadir {
        $basepath = $datadir
    } else {
        $basepath = "/var/lib/postgresql/${pgversion}/main"
    }
    file { "${basepath}/recovery.conf":
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
            command     => "/usr/bin/pg_basebackup -D ${basepath} -h ${master_server} -U replication -w",
            user        => 'postgres',
            unless      => "/usr/bin/test -f ${basepath}/PG_VERSION",
            require     => Class['postgresql::server'],
        }
    }
}
