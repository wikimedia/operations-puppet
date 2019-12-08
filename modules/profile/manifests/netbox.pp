# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, uwsgi
#       set up Netbox report alerts / automated running.
#
# Requires:
#
# Sample Usage:
#       include profile::netbox
#
class profile::netbox (
    Stdlib::Fqdn $active_server = lookup('profile::netbox::active_server'),
    Stdlib::Fqdn $nb_service_hostname = lookup('profile::netbox::service_hostname'),
    Optional[Array[String]] $slaves = lookup('profile::netbox::slaves', {'default_value' => undef}),

    Stdlib::Fqdn $redis_host = lookup('profile::netbox::redis::host'),
    Stdlib::Port $redis_port = lookup('profile::netbox::redis::port'),
    String $redis_password = lookup('profile::netbox::redis::password'),

    String $nb_token = lookup('profile::netbox::tokens::read_write'),
    String $nb_ro_token = lookup('profile::netbox::tokens::read_only'),

    String $nb_dump_interval = lookup('profile::netbox::dump_interval'),

    Stdlib::Fqdn $db_primary = lookup('profile::netbox::db::primary'),

    # These all live in private lookup
    String $db_password = lookup('profile::netbox::db::password'),
    String $secret_key = lookup('profile::netbox::secret_key'),
    #

    Boolean $include_ldap = lookup('profile::netbox::ldap', {'default_value' => true}),
    Boolean $deploy_acme = lookup('profile::netbox::acme', {'default_value' => true}),

    Stdlib::HTTPSUrl $nb_api = lookup('profile::netbox::netbox_api'),

    Optional[String] $ganeti_user = lookup('profile::ganeti::rapi::ro_user', {'default_value' => undef}),
    Optional[String] $ganeti_password = lookup('profile::ganeti::rapi::ro_password', {'default_value' => undef}),
    Optional[Integer] $ganeti_sync_interval = lookup('profile::netbox::ganeti_sync_interval', {'default_value' => undef}),
    Array[Hash[String, Scalar, 3, 3]] $nb_ganeti_profiles = lookup('profile::netbox::ganeti_sync_profiles', {'default_value' => []}),

    Optional[Stdlib::Fqdn] $puppetdb_host = lookup('puppetdb_host', {'default_value' => undef}),
    Optional[Stdlib::Port] $puppetdb_microservice_port = lookup('profile::puppetdb::microservice::port', {'default_value' => undef}),

    Optional[Array[Hash]] $nb_report_checks = lookup('profile::netbox::netbox_report_checks', {'default_value' => []}),

    Optional[String] $librenms_db_user = lookup('profile::librenms::dbuser', {'default_value' => undef}),
    Optional[String] $librenms_db_password = lookup('profile::librenms::dbpassword', {'default_value' => undef}),
    Optional[Stdlib::Fqdn] $librenms_db_host = lookup('profile::librenms::dbhost', {'default_value' => undef}),
    Optional[String] $librenms_db_name = lookup('profile::librenms::dbname', {'default_value' => undef}),
    Stdlib::Port $librenms_db_port = lookup('profile::librenms::dbport', {'default_value' => 3306}),

    Optional[Stdlib::HTTPUrl] $swift_auth_url = lookup('netbox::swift_auth_url', {'default_value' => undef}),
    Optional[String] $swift_user = lookup('netbox::swift_user', {'default_value' => undef}),
    Optional[String] $swift_key = lookup('netbox::swift_key', {'default_value' => undef}),
    Optional[String] $swift_container = lookup('netbox::swift_container', {'default_value' => undef}),
    Optional[String] $swift_url_key = lookup('netbox::swift_url_key', {'default_value' => undef}),

    Hash $ldap_config = lookup('ldap', Hash, hash, {}),
) {
    $nb_ganeti_ca_cert = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    $nb_puppetdb_ca_cert = $nb_ganeti_ca_cert
    $nb_swift_ca_cert =  $nb_ganeti_ca_cert
    $puppetdb_api = "https://${puppetdb_host}:${puppetdb_microservice_port}/"

    $extras_path = '/srv/deployment/netbox-extras/'

    # Used for LDAP auth
    include passwords::ldap::production
    $proxypass = $passwords::ldap::production::proxypass

    # packages required by netbox-extras
    require_package('python3-git', 'python3-pynetbox', 'python3-requests')

    class { '::netbox':
        service_hostname => $nb_service_hostname,
        directory        => '/srv/deployment/netbox/deploy/src',
        db_host          => $db_primary,
        db_password      => $db_password,
        secret_key       => $secret_key,
        ldap_password    => $proxypass,
        extras_path      => $extras_path,
        swift_auth_url   => $swift_auth_url,
        swift_user       => $swift_user,
        swift_key        => $swift_key,
        swift_ca         => $nb_swift_ca_cert,
        swift_container  => $swift_container,
        swift_url_key    => $swift_url_key,
        ldap_server      => $ldap_config['ro-server'],
        include_ldap     => $include_ldap,
        redis_host       => $redis_host,
        redis_port       => $redis_port,
        redis_password   => $redis_password,
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    class { '::sslcert::dhparam': }

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'ssl',
                    ],
    }

    ferm::service { 'netbox_https':
        proto => 'tcp',
        port  => '443',
        desc  => 'Public HTTPS for Netbox',
    }

    httpd::site { $nb_service_hostname:
        content => template('profile/netbox/netbox.wikimedia.org.erb'),
    }

    if $deploy_acme {
        acme_chief::cert { 'netbox':
            puppet_svc => 'apache2',
        }
    }

    if $active_server == $::fqdn {
        $active_ensure = 'present'
    } else {
        $active_ensure = 'absent'
    }

    monitoring::service { 'netbox-ssl':
        ensure        => $active_ensure,
        description   => 'netbox SSL',
        check_command => 'check_ssl_http_letsencrypt!netbox.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }

    monitoring::service { 'netbox-https':
        ensure        => $active_ensure,
        description   => 'netbox HTTPS',
        check_command => 'check_https_url!netbox.wikimedia.org!https://netbox.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }


    # Report Deployment
    #
    # FIXME service::uwsgi seems to create the directory /etc/netbox/, counter intuitively.
    #

    git::clone { 'operations/software/netbox-extras':
        ensure    => 'latest',
        directory => $extras_path,
    }

    # Configuration for the Netbox-Ganeti synchronizer
    file { '/etc/netbox/ganeti-sync.cfg':
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0400',
        content => template('profile/netbox/netbox-ganeti-sync.cfg.erb')
    }

    # Configuration for Netbox reports in general
    file { '/etc/netbox/reports.cfg':
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/netbox/netbox-reports.cfg.erb'),
    }

    # Configuration for Accounting report which contains secrets
    file { '/etc/netbox/gsheets.cfg':
        owner   => 'netbox',
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

    # configurations for other scripts (migrate to this configuration unless
    # there are special needs or permissions are complicated).
    file { '/etc/netbox/scripts.cfg':
        owner   => 'netbox',
        group   => 'netbox',
        mode    => '0440',
        content => template('profile/netbox/netbox-scripts.cfg.erb'),
    }

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
        $reportclass = $report['class']

        if $report['alert'] {
            $check_args = ''
        }
        else {
            $check_args = '-w'
        }
        if $report['check_interval'] {
            ::nrpe::monitor_service { "check_netbox_${repname}":
                ensure         => $active_ensure,
                description    => "Netbox report ${repname}.",
                nrpe_command   => "/usr/bin/python3 /usr/local/lib/nagios/plugins/check_netbox_report.py ${check_args} ${reportclass}",
                check_interval => $report['check_interval'],
                notes_url      => "https://netbox.wikimedia.org/extras/reports/${reportclass}/",
                contact_group  => 'team-dcops',
            }
        }
        else {
            ::nrpe::monitor_service { "check_netbox_${repname}":
                ensure    => absent,
                notes_url => 'https://wikitech.wikimedia.org/wiki/Netbox#Report_Alert',
            }
        }
        # This definitely should only be on one of the frontends
        if $report['run_interval'] {
            systemd::timer::job { "netbox_report_${repname}_run":
                ensure                    => $active_ensure,
                description               => "Run report ${reportclass} in Netbox.",
                command                   => "/srv/deployment/netbox/venv/bin/python /srv/deployment/netbox/deploy/src/netbox/manage.py runreport ${reportclass}",
                interval                  => {
                    'start'    => 'OnCalendar',
                    'interval' => $report['run_interval']
                },
                logging_enabled           => false,
                monitoring_enabled        => false,
                monitoring_contact_groups => 'admins',
                user                      => 'netbox',
            }
        }
        else {
            systemd::timer::job{ "netbox_report_${repname}_run":
                ensure       => absent,
            }
        }
    }

    # Ganeti Sync mechanics
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
            user                      => 'netbox',
        }
    }

    # Support directory for dumping tables
    file { '/srv/netbox-dumps/':
        ensure => 'directory',
        owner  => 'netbox',
        group  => 'netbox',
        mode   => '0770',
    }
    # Timer for dumping tables
    systemd::timer::job { 'netbox_dump_run':
        ensure                    => present,
        description               => 'Dump CSVs from Netbox.',
        command                   => '/srv/deployment/netbox/deploy/scripts/rotatedump',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => $nb_dump_interval,
        },
        logging_enabled           => false,
        monitoring_enabled        => false,
        monitoring_contact_groups => 'admins',
        user                      => 'netbox',
    }

    include ::profile::backup::host
    backup::set { 'netbox': }
}
