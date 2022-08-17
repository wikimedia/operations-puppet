# SPDX-License-Identifier: Apache-2.0
# Class: profile::dispatch::db
#
# This profile installs all the Dispatch related database things.
# Liberally copied from / inspired by profile::netbox::db
#
# Actions:
#       deploy and configure Postgresql for Dispatch (or a synchronous replica)
#
# Requires:
#
# Sample Usage:
#       include profile::dispatch::db
#
class profile::dispatch::db (
    String              $primary              = lookup('profile::dispatch::db::primary'),
    String              $password             = lookup('profile::dispatch::db::password'),
    String              $replication_password = lookup('profile::dispatch::db::replication_password'),
    String              $dump_interval        = lookup('profile::dispatch::db::dump_interval'),
    Array[Stdlib::Host] $replicas             = lookup('profile::dispatch::db::replicas'),
    Array[Stdlib::Host] $frontends            = lookup('profile::dispatch::db::frontends'),
    Boolean             $ipv6_ok              = lookup('profile::dispatch::db::ipv6_ok'),
    Boolean             $do_backups           = lookup('profile::dispatch::db::do_backup'),
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

            # User for standby dispatch server to query the primary DB
            postgresql::user { "dispatch@${secondary}-ipv4":
                ensure   => present,
                user     => 'dispatch',
                database => 'dispatch',
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
                    database => 'dispatch',
                    password => $replication_password,
                    cidr     => "${sec_ip6}/128",
                    master   => $on_primary,
                }
            }

        }

        if !empty($frontends) {
            $frontends_ferm = join($frontends, ' ')

            ferm::service { 'dispatch_fe':
                proto  => 'tcp',
                port   => '5432',
                srange => "(@resolve((${frontends_ferm})) @resolve((${frontends_ferm}), AAAA))",
            }
        }

        $frontends.each |$frontend| {
            # this cannot fail
            $fe_ip4 = ipresolve($frontend, 4)

            postgresql::user { "dispatch@${frontend}-ipv4":
                ensure   => present,
                user     => 'dispatch',
                database => 'dispatch',
                password => $password,
                cidr     => "${fe_ip4}/32",
                master   => $on_primary,
            }
            if $ipv6_ok {
                $fe_ip6 = ipresolve($frontend, 6)
                postgresql::user { "dispatch@${frontend}-ipv6":
                    ensure   => present,
                    user     => 'dispatch',
                    database => 'dispatch',
                    password => $password,
                    cidr     => "${fe_ip6}/128",
                    master   => $on_primary,
                }
            }
        }

        # Create the dispatch user for localhost
        # This works on every server and is used for read-only db lookups
        postgresql::user { 'dispatch@localhost':
            ensure   => present,
            user     => 'dispatch',
            database => 'dispatch',
            password => $password,
            master   => $on_primary,
        }

        # Create the database
        postgresql::db { 'dispatch':
            owner   => 'dispatch',
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
            ferm::service { 'dispatch_postgres':
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
            pg_database => 'dispatch',
            description => 'dispatch Postgres',
        }
        # On secondary nodes, do an hourly DB dump
        class { '::postgresql::backup':
            do_backups    => $do_backups,
            dump_interval => $dump_interval
        }
    }
    if $do_backups {
        include ::profile::backup::host
        backup::set { 'dispatch-postgres': }
    }
}
