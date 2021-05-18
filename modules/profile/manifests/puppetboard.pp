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
    String $puppetdb_host    = lookup('puppetdb_host'),
    String $flask_secret_key = lookup('profile::puppetboard::flask_secret_key'),
) {
    $port = 8001
    $base_path = '/srv/deployment/puppetboard'
    $config_path = "${base_path}/deploy"
    $venv_path = "${base_path}/venv"
    $directory = "${venv_path}/lib/python3.5/site-packages/puppetboard"
    $puppet_ssl_dir = puppet_ssldir()

    $packages = ['make', 'python3-pip', 'virtualenv']
    require_package($packages)

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { 'profile::rsyslog::udp_json_logback_compat': }


    file { "${base_path}/settings.py":
        ensure  => present,
        owner   => 'deploy-puppetboard',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/puppetboard/settings.py.erb'),
        before  => Uwsgi::App['puppetboard'],
        notify  => Service['uwsgi-puppetboard'],
    }

    # Puppetboard is controlled via a custom systemd unit (uwsgi-puppetboard),
    # so avoid the generic uwsgi sysvinit script shipped in the Debian package
    exec { 'mask_default_uwsgi_puppetboard':
        command => '/bin/systemctl mask uwsgi.service',
        creates => '/etc/systemd/system/uwsgi.service',
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
            buffer-size  => 8096,
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
        require         => Package[$packages],
    }

    base::service_auto_restart { 'uwsgi-puppetboard': }
    base::service_auto_restart { 'apache2': }

    ferm::service { 'apache2-http':
        proto => 'tcp',
        port  => '80',
    }

    class { 'httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http'],
    }

    profile::idp::client::httpd::site {'puppetboard.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-puppetboard.erb',
        required_groups  => ['cn=ops,ou=groups,dc=wikimedia,dc=org'],
        proxied_as_https => true,
        document_root    => $directory,
    }
}
