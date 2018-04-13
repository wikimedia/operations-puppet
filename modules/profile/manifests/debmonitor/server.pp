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
    String $internal_server_name = hiera('profile::debmonitor::server::internal_server_name'),
    String $django_secret_key = hiera('profile::debmonitor::server::django_secret_key'),
    String $django_mysql_db_host = hiera('profile::debmonitor::server::django_mysql_db_host'),
    String $django_mysql_db_password = hiera('profile::debmonitor::server::django_mysql_db_password'),
) {
    include ::passwords::ldap::production

    class { '::sslcert::dhparam': }

    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $base_path = '/srv/deployment/debmonitor'
    $config_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $static_path = "${base_path}/static/"
    $directory = "${config_path}/debmonitor"
    $ssl_config = ssl_ciphersuite('nginx', 'strong')

    file { "${base_path}/config.json":
        ensure  => present,
        owner   => 'deploy-debmonitor',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/debmonitor/server/config.json.erb'),
        before  => Uwsgi::App['debmonitor'],
        notify  => Service['uwsgi-debmonitor'],
    }

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
                "DEBMONITOR_CONFIG=${base_path}/config.json",
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

    ferm::service { 'nginx-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    ferm::service { 'nginx-https':
        proto => 'tcp',
        port  => '443',
    }

    sslcert::certificate { $internal_server_name:
        ensure       => present,
        skip_private => false,
        before       => Service['nginx'],
    }

    nginx::site { 'debmonitor':
        content => template('profile/debmonitor/server/nginx.conf.erb'),
    }
}
