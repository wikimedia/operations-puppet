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
    Array[Stdlib::Host] $replicas             = lookup('profile::dispatch::db::replicas'),
    Array[Stdlib::Host] $frontends            = lookup('profile::dispatch::db::frontends'),
    Boolean             $ipv6_ok              = lookup('profile::dispatch::db::ipv6_ok'),
    Boolean             $do_backups           = lookup('profile::dispatch::db::do_backup'),
) {
    # Inspired by modules/puppetprimary/manifests/puppetdb/database.pp
    if $primary == $facts['networking']['fqdn'] {

        class { '::postgresql::master':
            root_dir => '/srv/postgres',
            use_ssl  => true,
        }

        $replicas.each |$secondary| {
            $sec_ip4 = ipresolve($secondary, 4)

            # Main replication user
            postgresql::user { "replication@${secondary}-ipv4":
                ensure   => present,
                user     => 'replication',
                database => 'replication',
                password => $replication_password,
                cidr     => "${sec_ip4}/32",
                master   => true,
                attrs    => 'REPLICATION',
            }

            # User for standby dispatch server to query the primary DB
            postgresql::user { "dispatch@${secondary}-ipv4":
                ensure   => present,
                user     => 'dispatch',
                database => 'dispatch',
                password => $password,
                cidr     => "${sec_ip4}/32",
                master   => true,
            }

            if $ipv6_ok {
                $sec_ip6 = ipresolve($secondary, 6)
                postgresql::user { "replication@${secondary}-ipv6":
                    ensure   => present,
                    user     => 'replication',
                    database => 'replication',
                    password => $replication_password,
                    cidr     => "${sec_ip6}/128",
                    master   => true,
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
                    master   => true,
                }
            }
        }

        $frontends.each |$frontend| {
            # this cannot fail
            $fe_ip4 = ipresolve($frontend, 4)

            postgresql::user { "dispatch@${frontend}-ipv4":
                ensure   => present,
                user     => 'dispatch',
                database => 'dispatch',
                type     => 'hostssl',
                password => $password,
                cidr     => "${fe_ip4}/32",
                master   => true,
            }
            if $ipv6_ok {
                $fe_ip6 = ipresolve($frontend, 6)
                postgresql::user { "dispatch@${frontend}-ipv6":
                    ensure   => present,
                    user     => 'dispatch',
                    database => 'dispatch',
                    type     => 'hostssl',
                    password => $password,
                    cidr     => "${fe_ip6}/128",
                    master   => true,
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
            master   => true,
        }

        # Create the database
        postgresql::db { 'dispatch':
            owner   => 'dispatch',
            require => Class['postgresql::master'],
        }
        postgresql::user { 'prometheus@localhost':
            user     => 'prometheus',
            database => 'postgres',
            type     => 'local',
            method   => 'peer',
        }

        # On the primary node, do a daily DB dump
        class { '::postgresql::backup':
            do_backups    => $do_backups,
        }
    } else {
        class { '::postgresql::slave':
            master_server    => $primary,
            root_dir         => '/srv/postgres',
            replication_pass => $replication_password,
            use_ssl          => true,
            rep_app          => "replication-${::hostname}"
        }

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
            dump_interval => '*-*-* *:37:00',
        }
    }

    if $do_backups {
        include ::profile::backup::host
        backup::set { 'dispatch-postgres': }
    }

    $allowed_hosts = $replicas + $frontends
    if !empty($allowed_hosts) {
        $hosts_ferm = join($allowed_hosts, ' ')

        ferm::service { 'dispatch_postgres':
            proto  => 'tcp',
            port   => '5432',
            srange => "(@resolve((${hosts_ferm})) @resolve((${hosts_ferm}), AAAA))",
        }
    }
}
