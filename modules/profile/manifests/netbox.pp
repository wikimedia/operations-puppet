# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, gunicorn, configure reverse proxy to gunicorn, LDAP
#       authentication and database
#       set up Netbox report alerts / automated running.
#
# Requires:
#
# Sample Usage:
#       include profile::netbox
#
class profile::netbox (
    String $active_server = hiera('profile::netbox::active_server'),
    Optional[Array[String]] $slaves = hiera('profile::netbox::slaves', undef),
    Stdlib::Ipv4 $slave_ipv4 = hiera('profile::netbox::slave_ipv4'),
    Stdlib::Ipv6 $slave_ipv6 = hiera('profile::netbox::slave_ipv6'),
    String $nb_token = hiera('profile::netbox::tokens::read_write'),
    String $ganeti_user = hiera('profile::ganeti::rapi::ro_user'),
    String $ganeti_password = hiera('profile::ganeti::rapi::ro_password'),
    Integer $ganeti_sync_interval = hiera('profile::netbox::ganeti_sync_interval'),
    Stdlib::HTTPSUrl $nb_api = hiera('profile::netbox::netbox_api'),
    Stdlib::Host $puppetdb_host = hiera('puppetdb_host'),
    Integer $puppetdb_microservice_port = hiera('profile::puppetdb::microservice::port'),
    Array[Hash[String, Scalar, 3, 3]] $nb_ganeti_profiles = hiera('profile::netbox::ganeti_sync_profiles'),
    Array[Hash] $nb_report_checks = hiera('profile::netbox::netbox_report_checks'),
) {

    include passwords::netbox
    $db_password = $passwords::netbox::db_password
    $secret_key = $passwords::netbox::secret_key
    $replication_pass = $passwords::netbox::replication_password
    $nb_ganeti_ca_cert = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    $nb_puppetdb_ca_cert = $nb_ganeti_ca_cert
    $puppetdb_api = "https://${puppetdb_host}:${puppetdb_microservice_port}/"

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

    if $active_server == $::fqdn {
        $ganeti_sync_timer_ensure = 'present'
    } else {
        $ganeti_sync_timer_ensure = 'absent'
    }
    $nb_ganeti_profiles.each |Integer $prof_index, Hash $profile| {
        systemd::timer::job { "netbox_ganeti_${profile['profile']}_sync":
            ensure                    => $ganeti_sync_timer_ensure,
            description               => "Automatically access Ganeti API at ${profile['profile']} to synchronize to Netbox",
            command                   => "/srv/deployment/netbox/venv/bin/python3 /srv/deployment/netbox/deploy/scripts/ganeti-netbox-sync.py ${profile['profile']}",
            interval                  => {
                'start'    => 'OnCalendar',
                # Splay by 1 minute per profile, offset by 5 minutes from 00 (sync process takes far less than 1 minute)
                'interval' => "*-*-* *:${String($prof_index + 5, '%02d')}/${String($ganeti_sync_interval, '%02d')}:00",
            },
            logging_enabled           => false,
            monitoring_enabled        => true,
            monitoring_contact_groups => 'admins',
            user                      => 'deploy-librenms',
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
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }

    monitoring::service { 'netbox-https':
        ensure        => $monitoring_ensure,
        description   => 'netbox HTTPS',
        check_command => 'check_https_url!netbox.wikimedia.org!https://netbox.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }


    #
    # FIXME service::uwsgi seems to create the directory /etc/netbox/, counter intuitively.
    #

    # Configuration for the Netbox-Ganeti synchronizer
    file { '/etc/netbox/ganeti-sync.cfg':
        owner   => 'deploy-librenms',
        group   => 'www-data',
        mode    => '0400',
        content => template('profile/netbox/netbox-ganeti-sync.cfg.erb')
    }

    # Configuration for Netbox reports in general
    file { '/etc/netbox-reports.cfg':
        owner   => 'deploy-librenms',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/netbox/netbox-reports.cfg.erb'),
    }

    # Configuration for Accounting report which contains secrets
    file { '/etc/netbox/gsheets.cfg':
        owner   => 'deploy-librenms',
        group   => 'www-data',
        mode    => '0440',
        content => secret('netbox/gsheets.cfg'),
    }

    # Configurations for the report checker
    file { '/etc/netbox/report_check.yaml':
        owner   => 'root',
        group   => 'nagios',
        mode    => '0440',
        content => ordered_yaml({
            url   => $nb_api,
            token => $nb_token,
        })
    }

    # packages required by report checker
    require_package('python3-pynetbox', 'python3-requests')

    # Deploy the report checker
    file { '/usr/local/lib/nagios/plugins/check_netbox_report.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/icinga/check_netbox_report.py',
    }

    # Generate report checker icinga checks from Hier data
    $nb_report_checks.each |$report| {
        $repname = $report['name']
        $reports = $report['classes']

        if $report['alert'] {
            $check_args = ''
        }
        else {
            $check_args = '-w'
        }

        if $report['check_interval'] {
            ::nrpe::monitor_service { "check_netbox_${repname}":
                ensure         => $monitoring_ensure,
                description    => "Check the Netbox report(s) `${repname}` for fail status.",
                nrpe_command   => "/usr/bin/python3 /usr/local/lib/nagios/plugins/check_netbox_report.py ${check_args} ${reports}",
                check_interval => $report['check_interval'],
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Netbox#Reports',
            }
        }
        else {
            ::nrpe::monitor_service { "check_${repname}":
                ensure       => absent,
            }
        }
        if $report['run_interval'] {
            ::nrpe::monitor_service { "check_netbox_${repname}_run":
                ensure         => $monitoring_ensure,
                description    => "Run the Netbox report(s) `${repname}` and check for fail status.",
                nrpe_command   => "/usr/bin/python3 /usr/local/lib/nagios/plugins/check_netbox_report.py ${check_args} ${reports}",
                check_interval => $report['run_interval'],
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Netbox#Reports',
            }
        }
        else {
            ::nrpe::monitor_service { "check_${repname}_run":
                ensure       => absent,
            }
        }
    }
}
