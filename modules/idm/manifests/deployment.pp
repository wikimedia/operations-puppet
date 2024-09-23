# SPDX-License-Identifier: Apache-2.0

class idm::deployment (
    String              $project,
    Stdlib::Unixpath    $base_dir,
    String              $deploy_user,
    Stdlib::Fqdn        $redis_master,
    Integer             $uwsgi_process_count,
){

    ensure_packages(['python3-django', 'python3-django-captcha', 'python3-django-rq',
        'python3-jose', 'python3-ldap3', 'python3-openid', 'python3-paramiko',
        'python3-redis', 'python3-social-auth-core', 'python3-social-django',
        'python3-bitu-ldap', 'libjs-jquery', 'python3-djangorestframework',
        'python3-sshpubkeys', 'python3-mwclient', 'python3-qrcode', 'python3-pyotp',
        'python3-structlog'
        ])

    $uwsgi_socket = "/run/uwsgi/${project}.sock"

    file { '/usr/bin/bitu':
        ensure => present,
        source => 'puppet:///modules/idm/bitu_cli.sh'
    }

    # Create directory for static files.
    file { '/usr/share/bitu':
        ensure => directory,
    }

    git::clone { 'operations/software/bitu':
        ensure    => 'latest',
        directory => "${base_dir}/${project}",
        branch    => 'master',
        owner     => $deploy_user,
        group     => $deploy_user,
        source    => 'gerrit',
        notify    => Exec['collect static assets'],
    }

    exec { 'collect static assets':
        command     => '/usr/bin/bitu collectstatic  --no-input',
        notify      => Service['uwsgi-bitu', 'rq-bitu'],
        refreshonly => true,
    }

    uwsgi::app{ $project:
        monitoring => absent,
        settings   => {
            uwsgi => {
                'plugins'      => 'python3',
                'project'      => $project,
                'uid'          => $deploy_user,
                'base'         => "${base_dir}/%(project)/src/bitu",
                'env'          => [
                    "PYTHONPATH=/etc/${project}:\$PYTHONPATH",
                    'DJANGO_SETTINGS_MODULE=settings'
                ],
                'chdir'        => '%(base)/',
                'module'       => '%(project).wsgi:application',
                'master'       => true,
                'processes'    => $uwsgi_process_count,
                'socket'       => $uwsgi_socket,
                'chown-socket' => $deploy_user,
                'chmod-socket' => 660,
                'vacuum'       => true,
            }
        }
    }

    systemd::service { 'rq-bitu':
        ensure  => ($facts['networking']['hostname'] == $redis_master).bool2str('present', 'absent'),
        content => file('idm/rq-bitu.service')
    }
}
