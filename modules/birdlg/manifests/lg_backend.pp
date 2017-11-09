# == Class: birdlg::lg_backend
#
# Install Bird LG - backend
#
# Install lgproxy, the backend part of BirdLG, that talks to the local Bird instance
#
# === Parameters
#
# [*install_dir*]
#   Directory to install lgproxy
#
# [*access_list*]
#   BirdLG frontend allowed to connect to this backend
#
# [*port*]
#   Port for BirdLG backend to listen for inbound frontend requests
#
class birdlg::lg_backend(
    $install_dir='/srv/deployment/birdlgproxy/',
    $access_list=['127.0.0.1'],
    $port = 5000,
) {

  package { [
          'python-flask',
          'python-dnspython',
          'python-memcache',
          'whois',
          'traceroute',
      ]:
      ensure => present,
  }
    file { "${install_dir}/lgproxy.cfg":
        ensure  => present,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0440',
        content => template('birdlg/lgproxy.cfg.erb'),
    }

    file { '/var/run/bird/bird.ctl':
        group   => 'www-data',
    }

    service::uwsgi { 'lgproxy':
        port            => $port,
        deployment_user => 'deploy-librenms',
        config          => {
            need-plugins => 'python',
            chdir        => $install_dir,
            wsgi         => 'lgproxy.wsgi',
            vacuum       => true,
            http-socket  => "0.0.0.0:${port}",
            # T170189: make sure Python has a sane default encoding
            env          => [
                'LANG=C.UTF-8',
                'PYTHONENCODING=utf-8',
            ],
        },
        healthcheck_url => '/',
        icinga_check    => false,
        sudo_rules      => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lgproxy restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lgproxy start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lgproxy status',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lgproxy stop',
        ],
    }


}
