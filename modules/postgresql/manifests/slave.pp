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
#       Defaults to 9.3 in Ubuntu Trusty and 9.4 in Debian jessie.
#   ensure
#       Defaults to present
#   root_dir
#       See $postgresql::server::root_dir
#   use_ssl
#       Enable ssl for both clients and replication
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
    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
    },
    $ensure='present',
    $max_wal_senders=5,
    $root_dir='/var/lib/postgresql',
    $use_ssl=false,
    $ssldir=undef,
) {

    $data_dir = "${root_dir}/${pgversion}/main"

    class { '::postgresql::server':
        ensure    => $ensure,
        pgversion => $pgversion,
        includes  => [ $includes, 'slave.conf'],
        root_dir  => $root_dir,
        use_ssl   => $use_ssl,
        ssldir    => $ssldir,
    }

    file { "/etc/postgresql/${pgversion}/main/slave.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/slave.conf.erb'),
        require => Package["postgresql-${pgversion}"],
    }

    file { "${data_dir}/recovery.conf":
        ensure  => $ensure,
        owner   => 'postgres',
        group   => 'root',
        mode    => '0644',
        content => template('postgresql/recovery.conf.erb'),
        before  => Service[$::postgresql::server::service_name],
        require => Exec["pg_basebackup-${master_server}"],
    }

    # Having this file here helps perform slave initialization.
    # This file should not be deleted when performing slave init.
    file { "/etc/postgresql/${pgversion}/main/.pgpass":
        ensure  => $ensure,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0600',
        content => template('postgresql/.pgpass.erb'),
        require => Package["postgresql-${pgversion}"],
    }

    # Let's sync once all our content from the master
    if $ensure == 'present' {
        exec { "pg_basebackup-${master_server}":
            environment => "PGPASSWORD=${replication_pass}",
            command     => "/usr/bin/pg_basebackup -X stream -D ${data_dir} -h ${master_server} -U replication -w",
            user        => 'postgres',
            unless      => "/usr/bin/test -f ${data_dir}/PG_VERSION",
            before      => Service[$::postgresql::server::service_name],
        }
    }

    file { '/usr/bin/prometheus_postgresql_replication_lag':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/postgresql/prometheus/postgresql_replication_lag.sh',
    }
}
