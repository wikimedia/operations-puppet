# SPDX-License-Identifier: Apache-2.0
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
# @param service_hostname the fqdn of the service
# @param discovery_name The fqdn name used internally
# @param additional_sans A list of fqdn names to be added to the certificate SAN
# @param slaves list of secondary netbox serveres
# @param rw_token api read write token key
# @param ro_token api read only token key
# @param db_primary primary database name
# @param db_password primary database name
# @param secret_key django secret key
# @param authentication_provider Either ldap or cas
# @param ssl_provider Either cfssl or acme
# @param acme_certificate acme certificate name
# @param netbox_api netbox api url
# @param ganeti_user The ganeti user
# @param ganeti_password The ganeti password
# @param ganeti_sync_interval how frequently to sync with ganeti
# @param ganeti_sync_profiles list of profiles to sync and the config
# @param puppetdb_microservice_port the port where the puppetd micro service listens
# @param puppetdb_microservice_fqdn the fqdn where the puppetd micro service listens
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
# @param redis_host redis host
# @param ldap_config the ldap config for cas
# @param do_backups if we should perform backups
# @param http_proxy proxy server to use for outbound connections
# @param changelog_retention The number of days to retain logged changes (object creations, updates, and deletions).
#        Set this to 0 to retain changes in the database indefinitely.
# @param job_retention The number of days to retain job results (scripts and reports).
#        Set this to 0 to retain job results in the database indefinitely.
# @param validators a list of form validators to install
#        Set this to True to prefer IPv4 instead.
# @param cas_rename_attributes a mapping of attributes that should be renamed
# @param cas_group_attribute_mapping a mapping of attributes to netbox groups
# @param cas_group_mapping a mapping of ldap groups to local groups
# @param cas_group_required list of required groups
# @param cas_username_attribute cas attribute to use as a username
# @param cas_server_url the location of the cas server
# @param oidc_key the OIDC key to use
# @param oidc_secret the OIDC secret to use
class profile::netbox (
    Hash                        $ldap_config             = lookup('ldap'),
    Stdlib::Fqdn                $active_server           = lookup('profile::netbox::active_server'),
    Stdlib::Fqdn                $service_hostname        = lookup('profile::netbox::service_hostname'),
    Stdlib::Fqdn                $discovery_name          = lookup('profile::netbox::discovery_name'),
    Array[Stdlib::Host]         $additional_sans         = lookup('profile::netbox::additional_sans'),
    Array[String]               $slaves                  = lookup('profile::netbox::slaves'),
    String                      $deploy_project          = lookup('profile::netbox::deploy_project'),
    String                      $rw_token                = lookup('profile::netbox::rw_token'),
    String                      $ro_token                = lookup('profile::netbox::ro_token'),
    Stdlib::Fqdn                $db_primary              = lookup('profile::netbox::db_primary'),
    String                      $db_password             = lookup('profile::netbox::db_password'),
    String                      $secret_key              = lookup('profile::netbox::secret_key'),
    Enum['ldap', 'cas', 'oidc'] $authentication_provider = lookup('profile::netbox::authentication_provider'),
    Profile::Pki::Provider      $ssl_provider            = lookup('profile::netbox::ssl_provider'),
    Optional[String[1]]         $acme_certificate        = lookup('profile::netbox::acme_cetificate'),
    Stdlib::HTTPSUrl            $netbox_api              = lookup('profile::netbox::netbox_api'),
    Boolean                     $do_backups              = lookup('profile::netbox::do_backup'),
    Optional[Stdlib::HTTPUrl]   $http_proxy              = lookup('profile::netbox::http_proxy'),
    Integer[0]                  $changelog_retention     = lookup('profile::netbox::changelog_retention'),
    Integer[0]                  $job_retention           = lookup('profile::netbox::job_retention'),
    Array[String[1]]            $validators              = lookup('profile::netbox::validators'),
    Array[Profile::Netbox::Report_check] $report_checks  = lookup('profile::netbox::report_checks'),

    #ganeti config
    Optional[String]           $ganeti_user                 = lookup('profile::netbox::ganeti_user'),
    Optional[String]           $ganeti_password             = lookup('profile::netbox::ganeti_password'),
    Integer                    $ganeti_sync_interval        = lookup('profile::netbox::ganeti_sync_interval'),
    Array[Profile::Netbox::Ganeti_sync_profile] $ganeti_sync_profiles = lookup('profile::netbox::ganeti_sync_profiles'),

    # puppetdb config
    Optional[Stdlib::Port]     $puppetdb_microservice_port  = lookup('profile::netbox::puppetdb_microservice_port'),
    Optional[Stdlib::Fqdn]     $puppetdb_microservice_fqdn  = lookup('profile::netbox::puppetdb_microservice_fqdn'),


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
    Stdlib::Fqdn               $redis_host                  = lookup('profile::netbox::redis_host'),

    # CAS Config
    Hash[String, String]       $cas_rename_attributes       = lookup('profile::netbox::cas_rename_attributes'),
    Hash[String, Array]        $cas_group_attribute_mapping = lookup('profile::netbox::cas_group_attribute_mapping'),
    Hash[String, Array]        $cas_group_mapping           = lookup('profile::netbox::cas_group_mapping'),
    Array                      $cas_group_required          = lookup('profile::netbox::cas_group_required'),
    Optional[String]           $cas_username_attribute      = lookup('profile::netbox::cas_username_attribute'),
    Optional[Stdlib::HTTPSUrl] $cas_server_url              = lookup('profile::netbox::cas_server_url'),
    Optional[String]           $oidc_key                    = lookup('profile::netbox::oidc_service'),
    Optional[String]           $oidc_secret                 = lookup('profile::netbox::oidc_secret')
) {
    if $ssl_provider == 'acme' and !$acme_certificate {
        fail('must provide \$acme_certificate when using \$ssl_provider acme')
    }
    $ca_certs = '/etc/ssl/certs/ca-certificates.crt'
    # TODO: bring this in from profile::certificates
    $ganeti_ca_cert = '/etc/ssl/certs/wmf-ca-certificates.crt'
    $puppetdb_api = "https://${puppetdb_microservice_fqdn}:${puppetdb_microservice_port}/"

    # TODO: Note this prevents overriding other verify options
    # https://github.com/psf/requests/issues/3829
    $systemd_environment = {'REQUESTS_CA_BUNDLE' => '/etc/ssl/certs/ca-certificates.crt'}

    # Netbox deployment dirs configuration
    $netbox_venv_path = "/srv/deployment/${deploy_project}/venv"
    $netbox_src_path = "/srv/deployment/${deploy_project}/deploy/src"
    $netbox_config_path = "/srv/deployment/${deploy_project}/deploy"
    $netbox_extras_path = '/srv/deployment/netbox-extras'

    $netbox_scripts_path = '/srv/netbox'
    $run_report_command = 'runscript --user sre_bot'

    file { $netbox_scripts_path:
        ensure => directory,  # Create the parent directory for the one below
    }
    file { "${netbox_scripts_path}/customscripts":
        ensure => directory,
        owner  => 'www-data',  # needed for manual creation through the UI
        group  => 'netbox',  # needed for automatic sync
        mode   => '2775',  # needed for manually created files to have the 'netbox' group
    }

    # Used for LDAP auth
    include passwords::ldap::production
    $proxypass = $passwords::ldap::production::proxypass

    include passwords::redis
    $redis_password = ($redis_host == 'localhost').bool2str('', $passwords::redis::main_password)

    # Allow the creation of venvs and add packages required by netbox-extras
    ensure_packages(
        ['python3-venv', 'python3-git', 'python3-pynetbox', 'python3-requests'])

    # Make sure the deployment directory exists before creating sub-directories
    # Needs to happen before the netbox Class is instanciated
    file { '/srv/deployment/':
        ensure => directory
    }

    $active_ensure = ($active_server == $facts['networking']['fqdn']).bool2str('present', 'absent')

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { 'profile::rsyslog::udp_json_logback_compat': }
    class { 'netbox':
        service_hostname            => $service_hostname,
        discovery_name              => $discovery_name,
        db_host                     => $db_primary,
        db_password                 => $db_password,
        secret_key                  => $secret_key,
        ldap_password               => $proxypass,
        scripts_path                => $netbox_scripts_path,
        config_path                 => $netbox_config_path,
        src_path                    => $netbox_src_path,
        venv_path                   => $netbox_venv_path,
        swift_auth_url              => $swift_auth_url,
        swift_user                  => $swift_user,
        swift_key                   => $swift_key,
        swift_container             => $swift_container,
        swift_url_key               => $swift_url_key,
        ldap_server                 => $ldap_config['ro-server'],
        authentication_provider     => $authentication_provider,
        redis_port                  => $redis_port,
        local_redis_maxmem          => $redis_maxmem,
        redis_host                  => $redis_host,
        redis_password              => $redis_password,
        http_proxy                  => $http_proxy,
        changelog_retention         => $changelog_retention,
        job_retention               => $job_retention,
        validators                  => $validators,
        ca_certs                    => $ca_certs,
        cas_server_url              => $cas_server_url,
        cas_rename_attributes       => $cas_rename_attributes,
        cas_username_attribute      => $cas_username_attribute,
        cas_group_attribute_mapping => $cas_group_attribute_mapping,
        cas_group_mapping           => $cas_group_mapping,
        cas_group_required          => $cas_group_required,
        oidc_key                    => $oidc_key,
        oidc_secret                 => $oidc_secret,
        rq_netbox_ensure            => $active_ensure,
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    class { 'sslcert::dhparam': }
    case $ssl_provider {
        'acme_chief': {
            acme_chief::cert { $acme_certificate:
                puppet_svc => 'apache2',
            }
            # Only use the ec certs this allows us to match cfssl behaviour
            $ssl_paths = {
                'cert'    => "/etc/acmecerts/${acme_certificate}/live/ec-prime256v1.crt",
                'chain'   => "/etc/acmecerts/${acme_certificate}/live/ec-prime256v1.chain.crt",
                'chained' => "/etc/acmecerts/${acme_certificate}/live/ec-prime256v1.chained.crt",
                'key'     => "/etc/acmecerts/${acme_certificate}/live/ec-prime256v1.key",
            }
        }
        'cfssl': {
            $ssl_paths = profile::pki::get_cert('discovery', $service_hostname, {
                'hosts'  => [$facts['networking']['fqdn'], $discovery_name, $additional_sans].flatten.unique,
                'notify' => Service['apache2'],
            })
        }
        default: { fail("unsupported ssl_provider: ${ssl_provider}") }
    }


    ensure_packages('libapache2-mod-wsgi-py3')
    class { 'httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'ssl', 'wsgi'],
    }

    firewall::service { 'netbox_https':
        proto => 'tcp',
        port  => 443,
        desc  => 'Public HTTPS for Netbox',
    }

    httpd::site { $service_hostname:
        content => template('profile/netbox/netbox-apache.erb'),
    }

    profile::auto_restarts::service { 'apache2': }

    # Report Deployment
    #
    # FIXME service::uwsgi seems to create the directory /etc/netbox/, counter intuitively.
    #
    python_deploy::venv { $deploy_project:
        deploy_user => 'netbox',
    }

    git::systemconfig { 'safe.directory-netbox-src':
        settings => {
            'safe' => {
                'directory' => "/srv/deployment/${deploy_project}/current/src",
            },
        },
    }

    git::clone { 'operations/software/netbox-extras':
        ensure    => 'present',
        directory => $netbox_extras_path,
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

    # Deploy the report checker
    nrpe::plugin { 'check_netbox_report.py':
        source => 'puppet:///modules/icinga/check_netbox_report.py',
    }

    # Generate report checker icinga checks from Hiera data
    $report_checks.each |$report| {
        $repname = $report['name']
        $reportclass = $report['class']
        $reportid = $report['id']

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
                nrpe_command   => "${netbox_venv_path}/bin/python3 /usr/local/lib/nagios/plugins/check_netbox_report.py ${check_args} ${reportclass}",
                check_interval => $report['check_interval'],
                notes_url      => "https://netbox.wikimedia.org/extras/scripts/${reportid}/",
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
                environment     => $systemd_environment,
                command         => "${netbox_venv_path}/bin/python ${netbox_src_path}/netbox/manage.py ${run_report_command} ${reportclass}",
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

    # T311048#8017206
    # https://docs.netbox.dev/en/stable/administration/housekeeping/
    systemd::timer::job { 'netbox_housekeeping':
        ensure      => $active_ensure,
        description => 'Run Netbox Housekeeping cleanups',
        environment => $systemd_environment,
        command     => "${netbox_venv_path}/bin/python ${netbox_src_path}/netbox/manage.py housekeeping",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 3:10:00',
        },
        user        => 'netbox',
    }

    $ganeti_sync_profiles.each |Integer $prof_index, Hash $profile| {
        systemd::timer::job { "netbox_ganeti_${profile['profile']}_sync":
            ensure          => $active_ensure,
            description     => "Automatically access Ganeti API at ${profile['profile']} to synchronize to Netbox",
            environment     => $systemd_environment,
            command         => "${netbox_venv_path}/bin/python3 ${netbox_extras_path}/tools/ganeti-netbox-sync.py ${profile['profile']}",
            interval        => {
                'start'    => 'OnCalendar',
                # Splay by 1 minute per profile, offset by 5 minutes from 00 (sync process takes far less than 1 minute)
                'interval' => '*-*-* *:%02d/%02d:00'.sprintf($prof_index + 5, $ganeti_sync_interval),
            },
            logging_enabled => false,
            user            => 'netbox',
        }
    }

    if $do_backups {
      include profile::backup::host
      backup::set { 'netbox': }
    }
}
