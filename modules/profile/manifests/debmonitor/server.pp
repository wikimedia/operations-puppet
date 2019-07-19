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
    String $public_server_name       = hiera('profile::debmonitor::server::public_server_name'),
    String $internal_server_name     = hiera('debmonitor'),
    String $django_secret_key        = hiera('profile::debmonitor::server::django_secret_key'),
    String $django_mysql_db_host     = hiera('profile::debmonitor::server::django_mysql_db_host'),
    String $django_mysql_db_password = hiera('profile::debmonitor::server::django_mysql_db_password'),
    Hash $ldap_config                = lookup('ldap', Hash, hash, {}),
) {
    include ::passwords::ldap::production

    # Debmonitor depends on 'mysqlclient' Python package that in turn requires a MySQL connector
    # Make is required by the deploy system
    require_package(['libldap-2.4-2', 'libmariadb2', 'make', 'python3-pip', 'virtualenv'])

    class { '::sslcert::dhparam': }

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
    $settings_module = 'debmonitor.settings.prod'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $hosts = unique(concat(query_nodes('Class[Role::Debmonitor::Server]'), [$::fqdn]))
    $proxy_hosts = query_nodes('Class[Role::Cluster::Management]')
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
        port            => $port,
        no_workers      => 4,
        deployment_user => $deploy_user,
        config          => {
            need-plugins => 'python3',
            chdir        => $directory,
            venv         => $venv_path,
            wsgi         => 'debmonitor.wsgi',
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

    # Public endpoint: incoming traffic from cache_text for the WebUI
    ferm::service { 'nginx-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    # Internal endpoint: incoming updates from all production hosts via debmonitor CLI
    ferm::service { 'nginx-https':
        proto  => 'tcp',
        port   => '443',
        srange => '$DOMAIN_NETWORKS',
    }

    # Certificate for the internal endpoint
    sslcert::certificate { $internal_server_name:
        ensure       => present,
        skip_private => false,
        before       => Service['nginx'],
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

    monitoring::service { 'debmonitor-http':
        description   => 'debmonitor.wikimedia.org',
        check_command => "check_http_redirect!debmonitor.wikimedia.org!/!301!https://${public_server_name}/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
    }

    monitoring::service { 'debmonitor-https':
        description   => 'debmonitor.discovery.wmnet',
        check_command => 'check_https_unauthorized!debmonitor.discovery.wmnet!/!400',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
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
        command => "/usr/bin/systemd-cat -t 'debmonitor-maintenance' ${base_path}/run-django-command debmonitorgc",
        user    => $deploy_user,
        weekday => $times['weekday'],
        hour    => $times['hour'],
        minute  => $times['minute'],
    }
}
