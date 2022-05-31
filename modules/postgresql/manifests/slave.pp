# @summary
# This class installs the server in a slave configuration
# It will create the replication user
#   Actions:
#     Install/configure postgresql in a slave configuration
#
# @param master_server The FQDN of the master server to connect to
# @param replication_pass The password the replication user should use
# @param pgversion Defaults to 9.6 in Debian Stretch and 11 in Buster
# @param ensure Defaults to present
# @param max_wal_senders the max wal senders
# @param root_dir $postgresql::server::root_dir
# @param use_ssl Enable ssl for both clients and replication
# @param includes addtional include files
# @param rep_app The replication label to use for this host
# @param ssldir the ssl dir
# @param log_min_duration_statement log statments that take longer then this (seconds)
# @example
#  class {'postgresql::slave':
#       master_server => 'mserver',
#       replication_pass => 'mypass',
#  }
#
class postgresql::slave(
    Stdlib::Host               $master_server,
    String                     $replication_pass,
    String                     $ensure          = 'present',
    Integer                    $max_wal_senders = 5,
    Stdlib::Unixpath           $root_dir        = '/var/lib/postgresql',
    Boolean                    $use_ssl         = false,
    Array[String]              $includes        = [],
    Optional[String]           $rep_app         = undef,
    Optional[Numeric]          $pgversion       = undef,
    Optional[Stdlib::Unixpath] $ssldir          = undef,
    Optional[Integer[250]]     $log_min_duration_statement  = undef,
) {

    $_pgversion = $pgversion ? {
        undef   => debian::codename() ? {
            'stretch'  => 9.6,
            'buster'   => 11,
            'bullseye' => 13,
            default    => fail("${title} not supported by: ${debian::codename()})")
        },
        default => $pgversion,
    }
    $data_dir = "${root_dir}/${_pgversion}/main"

    class { 'postgresql::server':
        ensure                     => $ensure,
        pgversion                  => $_pgversion,
        includes                   => $includes + ['slave.conf'],
        root_dir                   => $root_dir,
        use_ssl                    => $use_ssl,
        ssldir                     => $ssldir,
        log_min_duration_statement => $log_min_duration_statement,
    }

    file { '/usr/local/bin/resync_replica':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/postgresql/resync_replica.sh',
    }

    file { "/etc/postgresql/${_pgversion}/main/slave.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/slave.conf.erb'),
        require => Package["postgresql-${_pgversion}"],
    }
    if $facts['postgres_replica_initialised'] {
        file { "${data_dir}/recovery.conf":
            ensure  => $ensure,
            owner   => 'postgres',
            group   => 'root',
            mode    => '0644',
            content => template('postgresql/recovery.conf.erb'),
            before  => Service[$postgresql::server::service_name],
        }
    } else {
        notify {'Replication not initialised please run: resync_replica': }
    }

    # Having this file here helps perform slave initialization.
    # This file should not be deleted when performing slave init.
    file { "/etc/postgresql/${_pgversion}/main/.pgpass":
        ensure  => $ensure,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0600',
        content => template('postgresql/.pgpass.erb'),
        require => Package["postgresql-${_pgversion}"],
    }

    file { '/usr/bin/prometheus_postgresql_replication_lag':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/postgresql/prometheus/postgresql_replication_lag.sh',
    }
}
