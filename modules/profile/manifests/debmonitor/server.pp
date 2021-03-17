# Class: profile::debmonitor::server
#
# This profile installs all the Debmonitor server related parts as WMF requires it
#
# Actions:
#       Deploy Debmonitor
#       Install nginx, uwsgi, configure reverse proxy to uwsgi
#
# Sample Usage:
#       include ::profile::debmonitor::server
#
class profile::debmonitor::server (
    String                    $internal_server_name     = lookup('debmonitor'),
    Hash                      $ldap_config              = lookup('ldap', Hash, hash, {}),
    String                    $public_server_name       = lookup('profile::debmonitor::server::public_server_name'),
    String                    $django_secret_key        = lookup('profile::debmonitor::server::django_secret_key'),
    String                    $django_mysql_db_host     = lookup('profile::debmonitor::server::django_mysql_db_host'),
    String                    $django_mysql_db_password = lookup('profile::debmonitor::server::django_mysql_db_password'),
    Boolean                   $django_log_db_queries    = lookup('profile::debmonitor::server::django_log_db_queries'),
    Boolean                   $django_require_login     = lookup('profile::debmonitor::server::django_require_login'),
    String                    $settings_module          = lookup('profile::debmonitor::server::settings_module'),
    String                    $app_deployment           = lookup('profile::debmonitor::server::app_deployment'),
    Enum['sslcert', 'puppet'] $ssl_certs                = lookup('profile::debmonitor::server::ssl_certs'),
) {
    include ::passwords::ldap::production

    # Make is required by the deploy system
    ensure_packages(['libldap-2.4-2', 'make', 'python3-pip', 'virtualenv'])

    # Debmonitor depends on 'mysqlclient' Python package that in turn requires a MySQL connector
    ensure_packages('libmariadb3')

    class { '::sslcert::dhparam': }

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { '::profile::rsyslog::udp_json_logback_compat': }


    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $deploy_user = 'deploy-debmonitor'
    $base_path = '/srv/deployment/debmonitor'
    $deploy_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $static_path = "${base_path}/static/"
    $config_path = "${base_path}/config.json"
    $directory = "${deploy_path}/src"
    $ssl_config = ssl_ciphersuite('nginx', 'strong')
    # Ensure to add FQDN of the current host also the first time the role is applied
    $hosts = unique(concat(query_nodes('Class[Role::Debmonitor::Server]'), [$::fqdn]))
    $proxy_hosts = query_nodes('Class[Role::Cluster::Management]')
    $proxy_images = query_nodes('Class[Role::Builder]')
    $ldap_server_primary = $ldap_config['ro-server']
    $ldap_server_fallback = $ldap_config['ro-server-fallback']

    # Configuration file for the Django-based WebUI and API
    file { $config_path:
        ensure  => present,
        owner   => $deploy_user,
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/debmonitor/server/config.json.erb'),
        before  => Uwsgi::App['debmonitor'],
        notify  => Service['uwsgi-debmonitor'],
    }

    # uWSGI service to serve the Django-based WebUI and API
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

    base::service_auto_restart { 'uwsgi-debmonitor': }
    base::service_auto_restart { 'apache2': }
    base::service_auto_restart { 'nginx': }

    # Public endpoint: incoming traffic from cache_text for the Web UI
    ferm::service { 'nginx-cdn-https':
        proto  => 'tcp',
        port   => '7443',
        srange => '$CACHES',
    }

    # Internal endpoint: incoming updates from all production hosts via debmonitor CLI
    ferm::service { 'nginx-https':
        proto  => 'tcp',
        port   => '443',
        srange => '$DOMAIN_NETWORKS',
    }

    # Certificate for the internal endpoint
    if $ssl_certs == 'sslcert' {
        sslcert::certificate { $internal_server_name:
            ensure       => present,
            skip_private => false,
            before       => Service['nginx'],
        }
    } else {
        base::expose_puppet_certs { '/etc/nginx':
            ensure          => present,
            provide_private => true,
            require         => Class['nginx'],
        }
    }

    # Static file Nginx configuration, including CSP header
    nginx::snippet { 'debmonitor_static':
        content => template('profile/debmonitor/server/debmonitor_static.nginx.erb'),
    }

    # Common Proxy settings
    nginx::snippet { 'debmonitor_proxy':
        content => template('profile/debmonitor/server/debmonitor_proxy.nginx.erb'),
    }

    nginx::site { 'debmonitor':
        content => template('profile/debmonitor/server/nginx.conf.erb'),
    }

    monitoring::service { 'debmonitor-cdn-https':
        description   => 'debmonitor.wikimedia.org:7443 CDN',
        check_command => 'check_https_redirect!7443!debmonitor.wikimedia.org!/!302!https://idp.wikimedia.org/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
    }

    monitoring::service { 'debmonitor-https':
        description   => 'debmonitor.discovery.wmnet:443 internal',
        check_command => 'check_https_unauthorized!debmonitor.discovery.wmnet!/!400',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
    }

    class { '::httpd':
        modules => ['proxy_http', 'proxy', 'auth_basic']
    }

    profile::idp::client::httpd::site {'debmonitor.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-debmonitor.erb',
        proxied_as_https => true,
        vhost_settings   => { 'uwsgi_port' => $port },
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
        ],
        enable_monitor   => false,
    }

    # Maintenance script
    file { "${base_path}/run-django-command":
        ensure  => present,
        owner   => $deploy_user,
        group   => $deploy_user,
        mode    => '0554',
        content => template('profile/debmonitor/server/run_django_command.sh.erb'),
    }

    # Maintenance cron
    $times = cron_splay($hosts, 'weekly', 'debmonitor-maintenance-gc')
    cron { 'debmonitor-maintenance-gc':
        command => "/usr/bin/systemd-cat -t 'debmonitor-maintenance' ${base_path}/run-django-command debmonitorgc || echo 'Debmonitor GC failed, check syslog for debmonitor-maintenance'",
        user    => $deploy_user,
        weekday => $times['weekday'],
        hour    => $times['hour'],
        minute  => $times['minute'],
    }
}
