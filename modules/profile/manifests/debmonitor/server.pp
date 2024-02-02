# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs all the Debmonitor server related parts as WMF requires it
# Actions:
#       Deploy Debmonitor
#       Install Apache, uwsgi, configure reverse proxy to uwsgi
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
# @param ssl_certs Indicate how sslcerts are managed (puppet or cfssl)
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
    Enum['puppet', 'cfssl']            $ssl_certs                = lookup('profile::debmonitor::server::ssl_certs'),
    Optional[String]                   $cfssl_label              = lookup('profile::debmonitor::server::cfssl_label'),
    Array[String]                      $required_groups          = lookup('profile::debmonitor::server::required_groups'),
    Stdlib::Filesource                 $trusted_ca_source        = lookup('profile::debmonitor::server::trusted_ca_source'),
) {
    if $ssl_certs == 'cfssl' and !$cfssl_label {
        fail('\$cfssl_label required when using cfssl')
    }
    include passwords::ldap::production

    # Starting with Bookworm Debmonitor uses the packaged Django stack from Debian
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

    # uWSGI service to serve the Django-based WebUI and API
    $socket = '/run/uwsgi/debmonitor.sock'
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
    if $ssl_certs == 'puppet' {
        $cert = $facts['puppet_config']['hostcert']
        $key = $facts['puppet_config']['hostprivkey']
    } elsif $ssl_certs == 'cfssl' {
        $ssl_paths = profile::pki::get_cert($cfssl_label, $internal_server_name, {
            profile => 'server',
            hosts   => [$facts['networking']['fqdn']],
        })
        $cert = $ssl_paths['cert']
        $key = $ssl_paths['key']
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
