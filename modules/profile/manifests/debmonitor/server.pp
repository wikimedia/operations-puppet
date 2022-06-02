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
    Hash                               $ldap_config              = lookup('ldap', Hash, hash, {}),
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

    # Make is required by the deploy system
    ensure_packages(['libldap-2.4-2', 'make', 'python3-pip', 'virtualenv'])

    # Debmonitor depends on 'mysqlclient' Python package that in turn requires a MySQL connector
    ensure_packages('libmariadb3')

    class { 'sslcert::dhparam': }

    if $enable_logback {
        # rsyslog forwards json messages sent to localhost along to logstash via kafka
        class { 'profile::rsyslog::udp_json_logback_compat': }
    }

    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $deploy_user = 'deploy-debmonitor'
    $base_path = '/srv/deployment/debmonitor'
    $deploy_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $static_path = "${base_path}/static/"
    $config_path = "${base_path}/config.json"
    $directory = "${deploy_path}/src"
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
        before  => Uwsgi::App['debmonitor'],
        notify  => Service['uwsgi-debmonitor'],
    }

    # uWSGI service to serve the Django-based WebUI and API
    $socket = '/run/uwsgi/debmonitor.sock'
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

    profile::auto_restarts::service { 'uwsgi-debmonitor': }
    profile::auto_restarts::service { 'apache2': }

    # Internal endpoint: incoming updates from all production hosts via debmonitor CLI
    ferm::service { 'apache-https':
        proto  => 'tcp',
        port   => '443',
        srange => '$DOMAIN_NETWORKS',
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

    # Maintenance script
    file { "${base_path}/run-django-command":
        ensure  => file,
        owner   => $deploy_user,
        group   => $deploy_user,
        mode    => '0554',
        content => template('profile/debmonitor/server/run_django_command.sh.erb'),
    }

    $times = cron_splay($hosts, 'weekly', 'debmonitor-maintenance-gc')
    systemd::timer::job { 'debmonitor-maintenance-gc':
        ensure      => present,
        command     => "${base_path}/run-django-command debmonitorgc",
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
    }
}
