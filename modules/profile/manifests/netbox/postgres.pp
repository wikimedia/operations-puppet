# Class: profile::netbox::postgres
#
# This profile installs all the Netbox related database things.
#
# Actions:
#       deploy and configure Postgresql for Netbox (or a synchronous replica)
#
# Requires:
#
# Sample Usage:
#       include profile::netbox::postgres
#
class profile::netbox::postgres (
    String $db_primary = lookup('profile::netbox::db::primary'),
    # private data
    String $db_password = lookup('profile::netbox::db::password'),
    String $replication_password = lookup('profile::netbox::db::replication_password'),
    #
    Array[Stdlib::Host] $db_secondaries = lookup('profile::netbox::db::secondaries', {'default_value' => []}),
    Array[Stdlib::Host] $frontends = lookup('profile::netbox::frontends', {'default_value' => []}),
    Boolean $ipv6_ok = lookup('profile::netbox::db::ipv6_ok', {'default_value' => true})
) {
    # Inspired by modules/puppetprimary/manifests/puppetdb/database.pp
    if $db_primary == $::fqdn {
        # We do this for the require in postgres::db
        $require_class = 'postgresql::master'
        class { '::postgresql::master':
            root_dir => '/srv/postgres',
            use_ssl  => true,
        }
        $on_primary = true

        $db_secondaries.each |$secondary| {
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
                password => $db_password,
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
                password => $db_password,
                cidr     => "${fe_ip4}/32",
                master   => $on_primary,
            }
            if $ipv6_ok {
                $fe_ip6 = ipresolve($frontend, 6)
                postgresql::user { "netbox@${frontend}-ipv6":
                    ensure   => present,
                    user     => 'netbox',
                    database => 'netbox',
                    password => $db_password,
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
            password => $db_password,
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

        if !empty($db_secondaries) {
            $secondaries_ferm = join($db_secondaries, ' ')
            # Access to postgres primary from postgres secondaries
            ferm::service { 'netbox_postgres':
                proto  => 'tcp',
                port   => '5432',
                srange => "(@resolve((${secondaries_ferm})) @resolve((${secondaries_ferm}), AAAA))",
            }
        }
    } else {
        $require_class = 'postgresql::slave'
        class { '::postgresql::slave':
            master_server    => $db_primary,
            root_dir         => '/srv/postgres',
            replication_pass => $replication_password,
            use_ssl          => true,
            rep_app          => "replication-${::hostname}"
        }
        $on_primary = false

        class { '::postgresql::slave::monitoring':
            pg_master   => $db_primary,
            pg_user     => 'replication',
            pg_password => $replication_password,
            pg_database => 'netbox',
            description => 'netbox Postgres',
        }
    }

    # Have backups because Netbox is used as a source of truth (T190184)
    include ::profile::backup::host
    backup::set { 'netbox-postgres': }
    class { '::postgresql::backup': }
}
