# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::postgresql
#
# Set up a postgresql cluster for data engineering purposes.
#
class profile::analytics::postgresql (
    Stdlib::Host        $primary              = lookup('profile::analytics::postgresql::primary'),
    String              $replication_password = lookup('profile::analytics::postgresql::replication_password'),
    String              $dump_interval        = lookup('profile::analytics::postgresql::dump_interval'),
    Array[Stdlib::Host] $replicas             = lookup('profile::analytics::postgresql::replicas'),
    Boolean             $ipv6_ok              = lookup('profile::analytics::postgresql::ipv6_ok', default_value => true),
    Boolean             $do_backups           = lookup('profile::analytics::postgresql::do_backup', default_value => true),
)
{
  # We continue to use non-inclusive language here until T280268 can be addressed
  # Inspired by profile::netbox::db
  if $primary == $facts['networking']['fqdn'] {
      # We do this for the require in postgres::db
      $require_class = 'postgresql::master'
      class { 'postgresql::master':
          root_dir => '/srv/postgres',
          use_ssl  => true,
      }
      $on_primary = true

      $replicas.each |$secondary| {
      $sec_ip4 = ipresolve($secondary, 4)

      # Main replication user
      postgresql::user { "replication@${secondary}-ipv4":
          ensure   => present,
          user     => 'replication',
          database => 'replication',
          password => $replication_password,
          cidr     => "${sec_ip4}/32",
          master   => $on_primary,
          attrs    => 'REPLICATION',
      }

      if $ipv6_ok {
        $sec_ip6 = ipresolve($secondary, 6)
        postgresql::user { "replication@${secondary}-ipv6":
          ensure   => present,
          user     => 'replication',
          database => 'replication',
          password => $replication_password,
          cidr     => "${sec_ip6}/128",
          master   => $on_primary,
          attrs    => 'REPLICATION',
        }
      }
      # On the primary node, do a daily DB dump
      class { 'postgresql::backup':
        do_backups    => $do_backups,
      }
    }
    if !empty($replicas) {
      $replicas_ferm = join($replicas, ' ')
      # Access to postgres primary from postgres replicas
      ferm::service { 'postgres_replication':
          proto  => 'tcp',
          port   => '5432',
          srange => "(@resolve((${replicas_ferm})) @resolve((${replicas_ferm}), AAAA))",
      }
    }
  }
  # Apply the following resources only to replica servers
  else {
      $require_class = 'postgresql::slave'
      class { 'postgresql::slave':
          master_server    => $primary,
          root_dir         => '/srv/postgres',
          replication_pass => $replication_password,
          use_ssl          => true,
          rep_app          => "replication-${::hostname}"
      }

      # On secondary nodes, do an hourly DB dump, keep 2 days of history
      class { 'postgresql::backup':
        do_backups    => $do_backups,
        dump_interval => $dump_interval,
        rotate_days   => 2
      }
    }

  # Apply the following resources to both primary and replica nodes
  postgresql::user { 'prometheus@localhost':
    user     => 'prometheus',
    database => 'postgres',
    type     => 'local',
    method   => 'peer',
  }
  if $do_backups {
    include profile::backup::host
    backup::set { 'data-engineering-postgres': }
  }
}
