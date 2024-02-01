# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs all the Debmonitor server related parts as WMF requires it
# Actions:
#       Deploy Debmonitor
#       Install nginx, uwsgi, configure reverse proxy to uwsgi
# @example
#       include ::profile::debmonitor::server
#
# @param internal_server_name the discovery domain used for debmonitor
# @param ldap_config The ldap configuration
# @param public_server_name The public domain to use
# @param django_secret_key The Django secret key
# @param django_mysql_db_host the Django mysql host
# @param django_mysql_db_password The Django mysql password
# @param django_log_db_queries Whether to log DB queries
# @param django_require_login whether to disable logins
# @param settings_module the settings module to use
# @param app_deployment How to deploy the APP
# @param enable_logback Enable logback
# @param enable_monitoring Enable monitoring
# @param ssl_certs Indicate how sslcerts are managed
# @param cfssl_label CFSSL label to use when requesting ssl certs.  Only valid if ssl_certs = 'cfssl'
# @param required_groups A list of ldap groups allowed to login
# @param trusted_ca_source Path to CA files used for MTLS truststore
class profile::debmonitor::server (
    String                             $internal_server_name     = lookup('debmonitor'),
    Hash                               $ldap_config              = lookup('ldap'),
    String                             $public_server_name       = lookup('profile::debmonitor::server::public_server_name'),
    String                             $django_secret_key        = lookup('profile::debmonitor::server::django_secret_key'),
    String                             $django_mysql_db_host     = lookup('profile::debmonitor::server::django_mysql_db_host'),
    String                             $django_mysql_db_password = lookup('profile::debmonitor::server::django_mysql_db_password'),
    Boolean                            $django_log_db_queries    = lookup('profile::debmonitor::server::django_log_db_queries'),
    Boolean                            $django_require_login     = lookup('profile::debmonitor::server::django_require_login'),
    String                             $settings_module          = lookup('profile::debmonitor::server::settings_module'),
    String                             $app_deployment           = lookup('profile::debmonitor::server::app_deployment'),
    Boolean                            $enable_logback           = lookup('profile::debmonitor::server::enable_logback'),
    Boolean                            $enable_monitoring        = lookup('profile::debmonitor::server::enable_monitoring'),
    Enum['sslcert', 'puppet', 'cfssl'] $ssl_certs                = lookup('profile::debmonitor::server::ssl_certs'),
    Optional[String]                   $cfssl_label              = lookup('profile::debmonitor::server::cfssl_label'),
    Array[String]                      $required_groups          = lookup('profile::debmonitor::server::required_groups'),
    Stdlib::Filesource                 $trusted_ca_source        = lookup('profile::debmonitor::server::trusted_ca_source'),
) {
    if $ssl_certs == 'cfssl' and !$cfssl_label {
        fail('\$cfssl_label required when using cfssl')
    }
    include passwords::ldap::production

    # Starting with Bookworm Debmonitor uses the packaged Django stack from Debian
    if debian::codename::ge('bookworm') {
        ensure_packages(['python3-django', 'python3-django-stronghold', 'python3-django-csp', 'python3-django-auth-ldap'])
        ensure_packages(['python3-mysqldb', 'debmonitor-server'])
        $deploy_user = 'www-data'
        $debmonitor_service_name = 'debmonitor-server'
        $debmonitor_shell_command = '/usr/bin/debmonitor'
        $static_path = '/usr/share/debmonitor/static/'
        $config_path = '/etc/debmonitor/config.json'
        $log_dir = '/var/log/debmonitor'
        $log_file = "${log_dir}/main.log"

        file {'/etc/uwsgi/apps-enabled/debmonitor.ini':
            ensure => link,
            target => '/etc/uwsgi/apps-available/debmonitor.ini',
            notify => Service[$debmonitor_service_name],
        }

        file {'/etc/uwsgi/apps-available/debmonitor.ini':
            ensure  => file,
            mode    => '0444',
            content => template('profile/debmonitor/server/debmonitor.ini.erb'),
            notify  => Service[$debmonitor_service_name],
        }

        file {$log_dir:
            ensure => directory,
            owner  => $deploy_user,
            group  => $deploy_user
        }

        logrotate::rule { 'debmonitor-uwsgi':
            file_glob     => "${log_dir}/*.log",
            frequency     => 'daily',
            copy_truncate => true,
            compress      => true,
            size          => '50M',
            rotate        => 10,
            missing_ok    => true,
        }

        service { 'debmonitor-server':
            ensure => 'running',
        }
    } else {
        # Make is required by the deploy system
        ensure_packages(['libldap-2.4-2', 'make', 'python3-pip', 'virtualenv'])
        # Debmonitor depends on 'mysqlclient' Python package that in turn requires a MySQL connector
        ensure_packages('libmariadb3')
        $deploy_user = 'deploy-debmonitor'
        $debmonitor_service_name = 'uwsgi-debmonitor'
        $base_path = '/srv/deployment/debmonitor'
        $debmonitor_shell_command = "${base_path}/run-django-command"
        $deploy_path = "${base_path}/deploy"
        $venv_path = "${base_path}/venv"
        $static_path = "${base_path}/static/"
        $config_path = "${base_path}/config.json"
        $directory = "${deploy_path}/src"
    }

    class { 'sslcert::dhparam': }

    if $enable_logback {
        # rsyslog forwards json messages sent to localhost along to logstash via kafka
        class { 'profile::rsyslog::udp_json_logback_compat': }
    }

    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $ssl_config = ssl_ciphersuite('apache', 'strong')
    # Ensure to add FQDN of the current host also the first time the role is applied
    $hosts = (wmflib::role::hosts('debmonitor::server') << $facts['networking']['fqdn']).sort.unique
    $proxy_hosts = wmflib::role::hosts('cluster::management')
    $proxy_images = wmflib::role::hosts('builder')
    $ldap_server_primary = $ldap_config['ro-server']
    $ldap_server_fallback = $ldap_config['ro-server-fallback']

    # Configuration file for the Django-based WebUI and API
    file { $config_path:
        ensure  => file,
        owner   => $deploy_user,
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/debmonitor/server/config.json.erb'),
        notify  => Service[$debmonitor_service_name],
    }

    # uWSGI service to serve the Django-based WebUI and API
    $socket = '/run/uwsgi/debmonitor.sock'
    if debian::codename::lt('bookworm') {
        service::uwsgi { 'debmonitor':
            deployment      => $app_deployment,
            port            => $port,
            no_workers      => 4,
            deployment_user => $deploy_user,
            config          => {
                need-plugins => 'python3',
                chdir        => $directory,
                venv         => $venv_path,
                wsgi         => 'debmonitor.wsgi',
                buffer-size  => 8192,
                vacuum       => true,
                http-socket  => "127.0.0.1:${port}",
                socket       => $socket,
                env          => [
                    # T164034: make sure Python has a sane default encoding
                    'LANG=C.UTF-8',
                    'LC_ALL=C.UTF-8',
                    'PYTHONENCODING=utf-8',
                    # Tell Debmonitor which configuration file to read
                    "DEBMONITOR_CONFIG=${config_path}",
                    # Tell Debmonitor which settings module to load
                    "DJANGO_SETTINGS_MODULE=${settings_module}",
                ],
            },
            healthcheck_url => '/',
            icinga_check    => false,
            sudo_rules      => [
                'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-debmonitor restart',
                'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-debmonitor start',
                'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-debmonitor status',
                'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-debmonitor stop',
            ],
        }

        # Maintenance script, this is provided by the Debian package and is only
        # required when deploying using SCAP
        file { $debmonitor_shell_command:
            ensure  => file,
            owner   => $deploy_user,
            group   => $deploy_user,
            mode    => '0554',
            content => template('profile/debmonitor/server/run_django_command.sh.erb'),
        }

    }
    profile::auto_restarts::service { $debmonitor_service_name: }
    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    # Internal endpoint: incoming updates from all production hosts via debmonitor CLI
    firewall::service { 'apache-https':
        proto    => 'tcp',
        port     => 443,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    class { 'httpd':
        modules => ['proxy_http', 'proxy', 'proxy_uwsgi', 'auth_basic', 'ssl', 'headers'],
    }

    profile::idp::client::httpd::site { $public_server_name:
        vhost_content    => 'profile/idp/client/httpd-debmonitor.erb',
        proxied_as_https => true,
        vhost_settings   => {
            'uwsgi_port'           => $port,
            'uwsgi_socket'         => $socket,
            'static_path'          => $static_path,
            'internal_server_name' => $internal_server_name,
        },
        required_groups  => $required_groups,
        enable_monitor   => false,
    }

    $trusted_ca_file = "/etc/ssl/localcerts/${internal_server_name}.trusted_ca.pem"
    file { $trusted_ca_file:
        ensure => file,
        mode   => '0444',
        source => $trusted_ca_source,
        notify => Service['apache2'],
    }
    case $ssl_certs {
        'sslcert': {
            $cert = "/etc/ssl/localcerts/${internal_server_name}.crt"
            $key = "/etc/ssl/private/${internal_server_name}.key"
        }
        'puppet': {
            $cert = $facts['puppet_config']['hostcert']
            $key = $facts['puppet_config']['hostprivkey']
        }
        'cfssl': {
            $ssl_paths = profile::pki::get_cert($cfssl_label, $internal_server_name, {
                profile => 'server',
                hosts   => [$facts['networking']['fqdn']],
            })
            $cert = $ssl_paths['cert']
            $key = $ssl_paths['key']
        }
        default: {
            # should't ever reach this
            fail("unsupported ssl provider: ${ssl_certs}")
        }
    }
    httpd::site { $internal_server_name:
        content => template('profile/debmonitor/internal_client_auth_endpoint.conf.erb'),
    }

    $times = cron_splay($hosts, 'weekly', 'debmonitor-maintenance-gc')
    systemd::timer::job { 'debmonitor-maintenance-gc':
        ensure      => present,
        command     => "${debmonitor_shell_command} debmonitorgc",
        user        => $deploy_user,
        description => 'Debmonitor GC',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => $times['OnCalendar'],
        },
    }

    if $enable_monitoring {
        monitoring::service { 'debmonitor-cdn-https':
            description   => 'debmonitor.wikimedia.org:7443 CDN',
            check_command => 'check_https_redirect!7443!debmonitor.wikimedia.org!/!302!https://idp.wikimedia.org/',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
        }

        monitoring::service { 'debmonitor-cdn-https-expiry':
            description   => 'debmonitor.wikimedia.org:7443 CDN SSL Expiry',
            check_command => 'check_https_expiry!debmonitor.wikimedia.org!7443',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
        }

        monitoring::service { 'debmonitor-https':
            description   => 'debmonitor.discovery.wmnet:443 internal',
            check_command => 'check_https_client_auth_puppet!debmonitor.discovery.wmnet!/client!200!HEAD',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
        }

        prometheus::blackbox::check::http { 'debmonitor-client-download':
            server_name     => 'debmonitor.discovery.wmnet',
            port            => 443,
            path            => '/client',
            use_client_auth => true,
            method          => 'HEAD',
            status_matches  => [200],
            probe_runbook   => 'https://wikitech.wikimedia.org/wiki/Debmonitor'

        }
    }
}
