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
    Array[String]       $databases            = lookup('profile::analytics::postgresql::databases', default_value => []),
    Hash[String,String] $users                = lookup('profile::analytics::postgresql::users', default_value => {}),
    Integer             $max_connections      = lookup('profile::analytics::postgresql::max_connections', default_value => 100)
)
{
  # We continue to use non-inclusive language here until T280268 can be addressed
  # Inspired by profile::netbox::db
  if $primary == $facts['networking']['fqdn'] {
      # We do this for the require in postgres::db
      $require_class = 'postgresql::master'
      class { 'postgresql::master':
          includes => ['tuning.conf'],
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
    firewall::service { 'postgres':
        proto    => 'tcp',
        port     => 5432,
        src_sets => ['ANALYTICS_NETWORKS', 'DSE_KUBEPODS_NETWORKS'],
    }
    # This is a simplistic method of creating users with an identically named database
    $users.each |$user, $pass| {
      postgresql::user { "${user}-ipv4" :
        ensure   => present,
        user     => $user,
        database => $user,
        password => $pass,
        cidr     => '10.0.0.0/8',
        master   => $on_primary,
      }
    }
    $users.each |$user, $pass| {
      postgresql::user { "${user}-ipv6" :
        ensure   => present,
        user     => $user,
        database => $user,
        password => $pass,
        cidr     => '2620:0:860::/46',
        master   => $on_primary,
      }
    }
    $databases.each |$database| {
      postgresql::db { $database:
        owner   => $database,
        require => Class['postgresql::master'],
      }
    }
  }
  # Apply the following resources only to replica servers
  else {
      $require_class = 'postgresql::slave'
      class { 'postgresql::slave':
          includes         => ['tuning.conf'],
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
        rotate_days   => 2,
      }
    }

  # Apply the following resources to both primary and replica nodes
  postgresql::user { 'prometheus@localhost':
    user     => 'prometheus',
    database => 'postgres',
    type     => 'local',
    method   => 'peer',
  }

  $pgversion = $::lsbdistcodename ? {
      'bullseye' => 13,
      'bookworm' => 15,
    }

  # Tuning
  file { "/etc/postgresql/${pgversion}/main/tuning.conf":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('profile/analytics/postgresql/tuning.conf.erb'),
  }

  if $do_backups {
    include profile::backup::host
    backup::set { 'data-engineering-postgres':
      jobdefaults => 'Daily-productionEqiad', # full backups every day
    }
  }
}
