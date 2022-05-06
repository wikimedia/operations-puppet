# @summary profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, uwsgi
#       set up Netbox report alerts / automated running.
#
# @example
#       include profile::netbox
# @param active_server the active netbox server
# @param service_hostname the active netbox server
# @param slaves list of secondery netbox serveres
# @param scap_repo The repo to use for scap deploys
# @param rw_token api read write token key
# @param ro_token api read only token key
# @param dump_interval how often to prefrom dumps
# @param db_primary primary database name
# @param db_password primary database name
# @param secret_key django secret key
# @param authentication_provider Either ldap or cas
# @param use_acme use acme certificates
# @param acme_certificate acme certificate name
# @param netbox_api netbox api url
# @param ganeti_user The ganeti user
# @param ganeti_password The ganeti password
# @param ganeti_sync_interval how frequently to sync with ganeti
# @param ganeti_sync_profiles list of profiles to sync and the config
# @param puppetdb_host the host of the puppetdb server
# @param puppetdb_microservice_port the port where the puppetd micro service listens
# @param report_checks a list of report checks
# @param librenms_db_user librenms DB user
# @param librenms_db_password librenms DB password
# @param librenms_db_host librenms DB host
# @param librenms_db_name librenms DB name
# @param swift_auth_url Swift auth url
# @param swift_user Swift user
# @param swift_key Swift key
# @param swift_url_key Swift url key
# @param swift_container Swift container
# @param redis_port redis port number
# @param redis_maxmem redis maximum memory
# @param ldap_config the ldap config for cas
# @param do_backups if we should perform backups
# @param cas_rename_attributes a mapping of attibutes that should be renamed
# @param cas_group_attribute_mapping a mapping of attibutes to netbox groups
# @param cas_group_mapping a mapping of ldap groups to local groups
# @param cas_group_required list of required groups
# @param cas_username_attribute cas attribute to use as a username
# @param cas_server_url the location of the cas server
class profile::netbox (
    Hash                       $ldap_config                 = lookup('ldap', Hash, hash, {}),
    Stdlib::Fqdn               $active_server               = lookup('profile::netbox::active_server'),
    Stdlib::Fqdn               $service_hostname            = lookup('profile::netbox::service_hostname'),
    Array[String]              $slaves                      = lookup('profile::netbox::slaves'),
    String                     $scap_repo                   = lookup('profile::netbox::scap_repo'),
    String                     $rw_token                    = lookup('profile::netbox::rw_token'),
    String                     $ro_token                    = lookup('profile::netbox::ro_token'),
    String                     $dump_interval               = lookup('profile::netbox::dump_interval'),
    Stdlib::Fqdn               $db_primary                  = lookup('profile::netbox::db_primary'),
    String                     $db_password                 = lookup('profile::netbox::db_password'),
    String                     $secret_key                  = lookup('profile::netbox::secret_key'),
    Enum['ldap', 'cas']        $authentication_provider     = lookup('profile::netbox::authentication_provider'),
    Boolean                    $use_acme                    = lookup('profile::netbox::use_acme'),
    String                     $acme_certificate            = lookup('profile::netbox::acme_cetificate'),
    Stdlib::HTTPSUrl           $netbox_api                  = lookup('profile::netbox::netbox_api'),
    Boolean                    $do_backups                  = lookup('profile::netbox::do_backup'),
    Array[Profile::Netbox::Report_check] $report_checks     = lookup('profile::netbox::report_checks'),

    #ganeti config
    Optional[String]           $ganeti_user                 = lookup('profile::netbox::ganeti_user'),
    Optional[String]           $ganeti_password             = lookup('profile::netbox::ganeti_password'),
    Integer                    $ganeti_sync_interval        = lookup('profile::netbox::ganeti_sync_interval'),
    Array[Profile::Netbox::Ganeti_sync_profile] $ganeti_sync_profiles = lookup('profile::netbox::ganeti_sync_profiles'),

    # puppetdb config
    Optional[Stdlib::Fqdn]     $puppetdb_host               = lookup('profile::netbox::puppetdb_host'),
    Optional[Stdlib::Port]     $puppetdb_microservice_port  = lookup('profile::netbox::puppetdb_microservice_port'),


    # Lirenms settings
    Optional[String]           $librenms_db_user            = lookup('profile::netbox::librenms_db_user'),
    Optional[String]           $librenms_db_password        = lookup('profile::netbox::librenms_db_password'),
    Optional[Stdlib::Fqdn]     $librenms_db_host            = lookup('profile::netbox::librenms_db_host'),
    Optional[String]           $librenms_db_name            = lookup('profile::netbox::librenms_db_name'),

    # swift config
    Optional[String]           $swift_user                  = lookup('profile::netbox::swift_user'),
    Optional[String]           $swift_key                   = lookup('profile::netbox::swift_key'),
    Optional[String]           $swift_container             = lookup('profile::netbox::swift_container'),
    Optional[String]           $swift_url_key               = lookup('profile::netbox::swift_url_key'),
    Optional[Stdlib::HTTPUrl]  $swift_auth_url              = lookup('profile::netbox::swift_auth_url'),

    # redis config
    Stdlib::Port               $redis_port                  = lookup('profile::netbox::redis_port'),
    Integer                    $redis_maxmem                = lookup('profile::netbox::redis_maxmem'),


    # CAS Config
    Hash[String, String]       $cas_rename_attributes       = lookup('profile::netbox::cas_rename_attributes'),
    Hash[String, Array]        $cas_group_attribute_mapping = lookup('profile::netbox::cas_group_attribute_mapping'),
    Hash[String, Array]        $cas_group_mapping           = lookup('profile::netbox::cas_group_mapping'),
    Array                      $cas_group_required          = lookup('profile::netbox::cas_group_required'),
    Optional[String]           $cas_username_attribute      = lookup('profile::netbox::cas_username_attribute'),
    Optional[Stdlib::HTTPSUrl] $cas_server_url              = lookup('profile::netbox::cas_server_url'),
) {
    $ca_certs = '/etc/ssl/certs/ca-certificates.crt'
    # TODO: bring this in from profile::certificates
    $ganeti_ca_cert = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    $puppetdb_api = "https://puppetdb-api.discovery.wmnet:${puppetdb_microservice_port}/"

    $extras_path = '/srv/deployment/netbox-extras/'

    # Used for LDAP auth
    include passwords::ldap::production
    $proxypass = $passwords::ldap::production::proxypass

    # packages required by netbox-extras
    ensure_packages(['python3-git', 'python3-pynetbox', 'python3-requests'])

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { 'profile::rsyslog::udp_json_logback_compat': }
    class { 'netbox':
        service_hostname            => $service_hostname,
        directory                   => '/srv/deployment/netbox/deploy/src',
        db_host                     => $db_primary,
        db_password                 => $db_password,
        secret_key                  => $secret_key,
        ldap_password               => $proxypass,
        extras_path                 => $extras_path,
        scap_repo                   => $scap_repo,
        swift_auth_url              => $swift_auth_url,
        swift_user                  => $swift_user,
        swift_key                   => $swift_key,
        swift_container             => $swift_container,
        swift_url_key               => $swift_url_key,
        ldap_server                 => $ldap_config['ro-server'],
        authentication_provider     => $authentication_provider,
        local_redis_port            => $redis_port,
        local_redis_maxmem          => $redis_maxmem,
        ca_certs                    => $ca_certs,
        cas_server_url              => $cas_server_url,
        cas_rename_attributes       => $cas_rename_attributes,
        cas_username_attribute      => $cas_username_attribute,
        cas_group_attribute_mapping => $cas_group_attribute_mapping,
        cas_group_mapping           => $cas_group_mapping,
        cas_group_required          => $cas_group_required,
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    class { 'sslcert::dhparam': }

    ensure_packages('libapache2-mod-wsgi-py3')
    class { 'httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'ssl', 'wsgi'],
    }

    ferm::service { 'netbox_https':
        proto => 'tcp',
        port  => '443',
        desc  => 'Public HTTPS for Netbox',
    }

    httpd::site { $service_hostname:
        content => template('profile/netbox/netbox.wikimedia.org.erb'),
    }

    profile::auto_restarts::service { 'apache2': }

    if $use_acme {
        acme_chief::cert { $acme_certificate:
            puppet_svc => 'apache2',
        }
    }

    $active_ensure = ($active_server == $facts['networking']['fqdn']).bool2str('present', 'absent')

    monitoring::service { 'netbox-ssl':
        ensure        => $active_ensure,
        description   => 'netbox SSL',
        check_command => "check_ssl_http_letsencrypt!${service_hostname}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }

    monitoring::service { 'netbox-https':
        ensure        => $active_ensure,
        description   => 'netbox HTTPS',
        check_command => "check_https_url!netbox.wikimedia.org!https://${service_hostname}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }

    monitoring::service { 'netbox-https-expiry':
        ensure        => $active_ensure,
        description   => 'netbox HTTPS expiry',
        check_command => 'check_https_expiry!netbox.wikimedia.org!443',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Netbox',
    }


    # Report Deployment
    #
    # FIXME service::uwsgi seems to create the directory /etc/netbox/, counter intuitively.
    #

    git::clone { 'operations/software/netbox-extras':
        ensure    => 'present',
        directory => $extras_path,
    }

    # Configuration for the Netbox-Ganeti synchronizer
    file { '/etc/netbox/ganeti-sync.cfg':
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0400',
        content => template('profile/netbox/netbox-ganeti-sync.cfg.erb'),
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
        content => to_yaml({
            url   => $netbox_api,
            token => $rw_token,
        }),
    }

    # configurations for other scripts (migrate to this configuration unless
    # there are special needs or permissions are complicated).
    file { '/etc/netbox/scripts.cfg':
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/netbox/netbox-scripts.cfg.erb'),
    }

    # Deploy the report checker
    file { '/usr/local/lib/nagios/plugins/check_netbox_report.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/icinga/check_netbox_report.py',
    }

    # Generate report checker icinga checks from Hier data
    $report_checks.each |$report| {
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
                description    => "Netbox report ${repname}",
                nrpe_command   => "/usr/bin/python3 /usr/local/lib/nagios/plugins/check_netbox_report.py ${check_args} ${reportclass}",
                check_interval => $report['check_interval'],
                notes_url      => "https://netbox.wikimedia.org/extras/reports/${reportclass}/",
                contact_group  => 'team-dcops',
            }
        }
        else {
            nrpe::monitor_service { "check_netbox_${repname}":
                ensure    => absent,
                notes_url => 'https://wikitech.wikimedia.org/wiki/Netbox#Report_Alert',
            }
        }
        # This definitely should only be on one of the frontends
        if $report['run_interval'] {
            systemd::timer::job { "netbox_report_${repname}_run":
                ensure          => $active_ensure,
                description     => "Run report ${reportclass} in Netbox",
                command         => "/srv/deployment/netbox/venv/bin/python /srv/deployment/netbox/deploy/src/netbox/manage.py runreport ${reportclass}",
                interval        => {
                    'start'    => 'OnCalendar',
                    'interval' => $report['run_interval'],
                },
                logging_enabled => false,
                user            => 'netbox',
            }
        }
        else {
            systemd::timer::job{ "netbox_report_${repname}_run":
                ensure       => absent,
            }
        }
    }

    $ganeti_sync_profiles.each |Integer $prof_index, Hash $profile| {
        systemd::timer::job { "netbox_ganeti_${profile['profile']}_sync":
            ensure                    => $active_ensure,
            description               => "Automatically access Ganeti API at ${profile['profile']} to synchronize to Netbox",
            command                   => "/srv/deployment/netbox/venv/bin/python3 /srv/deployment/netbox-extras/tools/ganeti-netbox-sync.py ${profile['profile']}",
            interval                  => {
                'start'    => 'OnCalendar',
                # Splay by 1 minute per profile, offset by 5 minutes from 00 (sync process takes far less than 1 minute)
                'interval' => '*-*-* *:%02d/%02d:00'.sprintf($prof_index + 5, $ganeti_sync_interval),
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
        command                   => '/srv/deployment/netbox-extras/tools/rotatedump',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => $dump_interval,
        },
        logging_enabled           => false,
        monitoring_enabled        => false,
        monitoring_contact_groups => 'admins',
        user                      => 'netbox',
    }

    if $do_backups {
      include profile::backup::host
      backup::set { 'netbox': }
    }
}
