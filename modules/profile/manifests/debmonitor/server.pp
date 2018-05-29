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
    String $public_server_name = hiera('profile::debmonitor::server::public_server_name'),
    String $internal_server_name = hiera('debmonitor'),
    String $django_secret_key = hiera('profile::debmonitor::server::django_secret_key'),
    String $django_mysql_db_host = hiera('profile::debmonitor::server::django_mysql_db_host'),
    String $django_mysql_db_password = hiera('profile::debmonitor::server::django_mysql_db_password'),
) {
    include ::passwords::ldap::production

    # Debmonitor depends on 'mysqlclient' Python package that in turn requires a MySQL connector
    # Make is required by the deploy system
    require_package(['libmariadb2', 'make'])

    class { '::sslcert::dhparam': }

    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $base_path = '/srv/deployment/debmonitor'
    $config_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $static_path = "${base_path}/static/"
    $directory = "${config_path}/debmonitor"
    $ssl_config = ssl_ciphersuite('nginx', 'strong')

    # Configuration file for the Django-based WebUI and API
    file { "${base_path}/config.json":
        ensure  => present,
        owner   => 'deploy-debmonitor',
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
        deployment_user => 'deploy-debmonitor',
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
                "DEBMONITOR_CONFIG=${base_path}/config.json",
                # Tell Debmonitor which settings module to load
                'DJANGO_SETTINGS_MODULE=debmonitor.settings.prod',
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

    # Public endpoint: incoming traffic from cache-misc for the WebUI
    ferm::service { 'nginx-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
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

    nginx::site { 'debmonitor':
        content => template('profile/debmonitor/server/nginx.conf.erb'),
    }
}
