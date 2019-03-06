# Class: profile::puppetboard
#
# This profile installs all the Puppetboard related parts as WMF requires it
#
# Actions:
#       Deploy Puppetboard
#       Install apache, uwsgi, configure reverse proxy to uwsgi
#
# Sample Usage:
#       include ::profile::puppetboard
#
class profile::puppetboard (
    String $puppetdb_host = hiera('puppetdb_host'),
    String $flask_secret_key = hiera('profile::puppetboard::flask_secret_key'),
) {
    include passwords::ldap::production

    $ldap_password = $passwords::ldap::production::proxypass
    $port = 8001
    $base_path = '/srv/deployment/puppetboard'
    $config_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $directory = "${venv_path}/lib/python3.5/site-packages/puppetboard"
    $puppet_ssl_dir = puppet_ssldir()

    require_package('make', 'python3-pip', 'virtualenv')

    file { "${base_path}/settings.py":
        ensure  => present,
        owner   => 'deploy-puppetboard',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/puppetboard/settings.py.erb'),
        before  => Uwsgi::App['puppetboard'],
        notify  => Service['uwsgi-puppetboard'],
    }

    service::uwsgi { 'puppetboard':
        port            => $port,
        no_workers      => 4,
        deployment_user => 'deploy-puppetboard',
        config          => {
            need-plugins => 'python3',
            chdir        => $directory,
            venv         => $venv_path,
            wsgi         => 'puppetboard.wsgi',
            vacuum       => true,
            http-socket  => "127.0.0.1:${port}",
            # T164034: make sure Python has a sane default encoding
            env          => [
                'LANG=C.UTF-8',
                'LC_ALL=C.UTF-8',
                'PYTHONENCODING=utf-8',
            ],
        },
        healthcheck_url => '/',
        icinga_check    => false,
        sudo_rules      => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-puppetboard restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-puppetboard start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-puppetboard status',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-puppetboard stop',
        ],
    }

    base::service_auto_restart { 'uwsgi-puppetboard': }

    ferm::service { 'apache2-http':
        proto => 'tcp',
        port  => '80',
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap', 'proxy', 'proxy_http'],
    }

    httpd::site { 'puppetboard.wikimedia.org':
        content => template('profile/puppetboard/puppetboard.wikimedia.org.erb'),
    }

    monitoring::service { 'puppetboard-http':
        description   => 'puppetboard.wikimedia.org',
        check_command => 'check_http_unauthorized!puppetboard.wikimedia.org!/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Puppet#PuppetDB',
    }
}
