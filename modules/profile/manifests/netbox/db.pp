# SPDX-License-Identifier: Apache-2.0
# Class: profile::netbox::db
#
# This profile installs all the Netbox related database things.
#
# Actions:
#       deploy and configure Postgresql for Netbox (or a synchronous replica)
#
# Requires:
#
# Sample Usage:
#       include profile::netbox::db
#
class profile::netbox::db (
    String              $primary              = lookup('profile::netbox::db::primary'),
    String              $password             = lookup('profile::netbox::db::password'),
    String              $replication_password = lookup('profile::netbox::db::replication_password'),
    String              $dump_interval        = lookup('profile::netbox::db::dump_interval'),
    Array[Stdlib::Host] $replicas             = lookup('profile::netbox::db::replicas'),
    Array[Stdlib::Host] $frontends            = lookup('profile::netbox::db::frontends'),
    Boolean             $ipv6_ok              = lookup('profile::netbox::db::ipv6_ok'),
    Boolean             $do_backups           = lookup('profile::netbox::db::do_backup'),
) {
    # Inspired by modules/puppetprimary/manifests/puppetdb/database.pp
    if $primary == $facts['networking']['fqdn'] {
        # We do this for the require in postgres::db
        $require_class = 'postgresql::master'
        class { '::postgresql::master':
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

            # User for standby netbox server to query the primary DB
            postgresql::user { "netbox@${secondary}-ipv4":
                ensure   => present,
                user     => 'netbox',
                database => 'netbox',
                password => $password,
                cidr     => "${sec_ip4}/32",
                master   => $on_primary,
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
                # User for monitoring check running on secondary server
                # who needs replication user rights and uses IPv6 (T185504)
                postgresql::user { "replication-monitoring@${secondary}-ipv6":
                    ensure   => present,
                    user     => 'replication',
                    database => 'netbox',
                    password => $replication_password,
                    cidr     => "${sec_ip6}/128",
                    master   => $on_primary,
                }
            }

        }

        if !empty($frontends) {
            $frontends_ferm = join($frontends, ' ')

            ferm::service { 'netbox_fe':
                proto  => 'tcp',
                port   => '5432',
                srange => "(@resolve((${frontends_ferm})) @resolve((${frontends_ferm}), AAAA))",
            }
        }

        $frontends.each |$frontend| {
            # this cannot fail
            $fe_ip4 = ipresolve($frontend, 4)

            postgresql::user { "netbox@${frontend}-ipv4":
                ensure   => present,
                user     => 'netbox',
                database => 'netbox',
                password => $password,
                cidr     => "${fe_ip4}/32",
                master   => $on_primary,
            }
            if $ipv6_ok {
                $fe_ip6 = ipresolve($frontend, 6)
                postgresql::user { "netbox@${frontend}-ipv6":
                    ensure   => present,
                    user     => 'netbox',
                    database => 'netbox',
                    password => $password,
                    cidr     => "${fe_ip6}/128",
                    master   => $on_primary,
                }
            }
        }

        # Create the netbox user for localhost
        # This works on every server and is used for read-only db lookups
        postgresql::user { 'netbox@localhost':
            ensure   => present,
            user     => 'netbox',
            database => 'netbox',
            password => $password,
            master   => $on_primary,
        }

        # Create the database
        postgresql::db { 'netbox':
            owner   => 'netbox',
            require => Class[$require_class],
        }
        postgresql::user { 'prometheus@localhost':
            user     => 'prometheus',
            database => 'postgres',
            type     => 'local',
            method   => 'peer',
        }

        if !empty($replicas) {
            $replicas_ferm = join($replicas, ' ')
            # Access to postgres primary from postgres replicas
            ferm::service { 'netbox_postgres':
                proto  => 'tcp',
                port   => '5432',
                srange => "(@resolve((${replicas_ferm})) @resolve((${replicas_ferm}), AAAA))",
            }
        }
        # On the primary node, do a daily DB dump
        class { '::postgresql::backup':
            do_backups    => $do_backups,
        }
    } else {
        $require_class = 'postgresql::slave'
        class { '::postgresql::slave':
            master_server    => $primary,
            root_dir         => '/srv/postgres',
            replication_pass => $replication_password,
            use_ssl          => true,
            rep_app          => "replication-${::hostname}"
        }
        $on_primary = false

        class { '::postgresql::slave::monitoring':
            pg_master   => $primary,
            pg_user     => 'replication',
            pg_password => $replication_password,
            pg_database => 'netbox',
            description => 'netbox Postgres',
        }
        # On secondary nodes, do an hourly DB dump, keep 2 days of history
        class { '::postgresql::backup':
            do_backups    => $do_backups,
            dump_interval => $dump_interval,
            rotate_days   => 2
        }
    }
    if $do_backups {
        include ::profile::backup::host
        backup::set { 'netbox-postgres': }
    }
}
