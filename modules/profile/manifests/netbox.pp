# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, gunicorn, configure reverse proxy to gunicorn, LDAP
#       authentication and database
#
# Requires:
#
# Sample Usage:
#       include profile::netbox
#
class profile::netbox (
    $active_server = hiera('profile::netbox::active_server'),
    $slaves = hiera('profile::netbox::slaves', undef),
    $slave_ipv4 = hiera('profile::netbox::slave_ipv4'),
    $slave_ipv6 = hiera('profile::netbox::slave_ipv6'),
) {

    include passwords::netbox
    $db_password = $passwords::netbox::db_password
    $secret_key = $passwords::netbox::secret_key
    $replication_pass = $passwords::netbox::replication_password

    $reports_path = '/srv/deployment/netbox-reports'

    # Have backups because Netbox is used as a source of truth (T190184)
    include ::profile::backup::host
    backup::set { 'netbox': }
    class { '::postgresql::backup': }

    # Used for LDAP auth
    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    # Define master postgres server
    $master = $active_server

    # Inspired by modules/puppetmaster/manifests/puppetdb/database.pp
    if $master == $::fqdn {
        # We do this for the require in postgres::db
        $require_class = 'postgresql::master'
        class { '::postgresql::master':
            root_dir => '/srv/postgres',
            use_ssl  => true,
        }
        $on_master = true
        postgresql::user { 'replication@netmon2001-ipv4':
            ensure   => present,
            user     => 'replication',
            database => 'replication',
            password => $replication_pass,
            cidr     => "${slave_ipv4}/32",
            master   => $on_master,
            attrs    => 'REPLICATION',
        }
        postgresql::user { 'replication@netmon2001-ipv6':
            ensure   => present,
            user     => 'replication',
            database => 'replication',
            password => $replication_pass,
            cidr     => "${slave_ipv6}/128",
            master   => $on_master,
            attrs    => 'REPLICATION',
        }
        # User for standby netbox server to query the master DB
        postgresql::user { 'netbox@netmon2001':
            ensure   => present,
            user     => 'netbox',
            database => 'netbox',
            password => $db_password,
            cidr     => "${slave_ipv4}/32",
            master   => $on_master,
        }
        # User for monitoring check running on slave server
        # who needs replication user rights and uses IPv6 (T185504)
        postgresql::user { 'netbox@netmon2001-ipv6':
            ensure   => present,
            user     => 'replication',
            database => 'netbox',
            password => $replication_pass,
            cidr     => "${slave_ipv6}/128",
            master   => $on_master,
        }

        # Create the netbox user for localhost
        # This works on every server and is used for read-only db lookups
        postgresql::user { 'netbox@localhost':
            ensure   => present,
            user     => 'netbox',
            database => 'netbox',
            password => $db_password,
            master   => $on_master,
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

        if $slaves {
            $slaves_ferm = join($slaves, ' ')
            # Access to postgres master from postgres slaves
            ferm::service { 'netbox_postgres':
                proto  => 'tcp',
                port   => '5432',
                srange => "(@resolve((${slaves_ferm})) @resolve((${slaves_ferm}), AAAA))",
            }
        }

    } else {
        $require_class = 'postgresql::slave'
        class { '::postgresql::slave':
            master_server    => $master,
            root_dir         => '/srv/postgres',
            replication_pass => $replication_pass,
            use_ssl          => true,
        }
        $on_master = false

        class { '::postgresql::slave::monitoring':
            pg_master   => $master,
            pg_user     => 'replication',
            pg_password => $replication_pass,
            pg_database => 'netbox',
            description => 'netbox Postgres',
        }
    }

    git::clone { 'operations/software/netbox-reports':
        ensure    => 'latest',
        directory => $reports_path,
    }

    class { '::netbox':
        directory     => '/srv/deployment/netbox/deploy/src',
        db_password   => $db_password,
        secret_key    => $secret_key,
        ldap_password => $proxypass,
        reports_path  => $reports_path,
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { 'netbox.wikimedia.org':
        content => template('profile/netbox/netbox.wikimedia.org.erb'),
    }

    acme_chief::cert { 'netbox':
        puppet_svc => 'apache2',
    }
    if $active_server == $::fqdn {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }

    monitoring::service { 'netbox-ssl':
        ensure        => $monitoring_ensure,
        description   => 'netbox SSL',
        check_command => 'check_ssl_http_letsencrypt!netbox.wikimedia.org',
    }

    monitoring::service { 'netbox-https':
        ensure        => $monitoring_ensure,
        description   => 'netbox HTTPS',
        check_command => 'check_https_url!netbox.wikimedia.org!https://netbox.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }
}
