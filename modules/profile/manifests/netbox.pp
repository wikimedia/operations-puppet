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
) {

# lint:ignore:wmf_styleguide
    include ::apache
    include ::apache::mod::headers
    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    include ::apache::mod::wsgi
# lint:endignore

    include passwords::netbox
    $db_password = $passwords::netbox::db_password
    $secret_key = $passwords::netbox::secret_key
    $replication_pass = $passwords::netbox::replication_password

    # Used for LDAP auth
    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    # Define master postgres server
    $master = 'netmon1002.wikimedia.org'

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
            cidr     => '208.80.153.110/32',
            master   => $on_master,
            attrs    => 'REPLICATION',
        }
        postgresql::user { 'replication@netmon2001-ipv6':
            ensure   => present,
            user     => 'replication',
            database => 'replication',
            password => $replication_pass,
            cidr     => '2620:0:860:4:208:80:153:110/128',
            master   => $on_master,
            attrs    => 'REPLICATION',
        }
        # User for standby netbox server to query the master DB
        postgresql::user { 'netbox@netmon2001':
            ensure   => present,
            user     => 'netbox',
            database => 'netbox',
            password => $db_password,
            cidr     => '208.80.153.110/32',
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
    }

    class { '::netbox':
        directory     => '/srv/deployment/netbox/deploy/netbox',
        db_password   => $db_password,
        secret_key    => $secret_key,
        ldap_password => $proxypass,
        admins        => '("Ops Team", "ops@lists.wikimedia.org")',
    }
    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    apache::site { 'netbox.wikimedia.org':
        content => template('profile/netbox/netbox.wikimedia.org.erb'),
    }

    letsencrypt::cert::integrated { 'netbox':
        subjects   => 'netbox.wikimedia.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
        require    => Class['apache::mod::ssl'],
    }
    if $active_server == $::fqdn {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }

    monitoring::service { 'netbox-ssl':
        ensure        => $monitoring_ensure,
        description   => 'Netbox SSL',
        check_command => 'check_ssl_http_letsencrypt!netbox.wikimedia.org',
    }

    monitoring::service { 'netbox-https':
        ensure        => $monitoring_ensure,
        description   => 'Netbox HTTPS',
        check_command => 'check_https_url!netbox.wikimedia.org!https://netbox.wikimedia.org',
    }
}
