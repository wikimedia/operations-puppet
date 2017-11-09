# == Class: librenms
#
# This class installs & manages Bird and lgproxy, the backend part of BirdLG
#
class birdlg::lg_backend(
    $install_dir='/srv/deployment/birdlg/',
    $access_list=['127.0.0.1'],
    $port = 5000,
) {

  package { [
          'python-flask',
          'python-dnspython',
          'python-memcache',
          'whois',
          'traceroute',
          'bird',
      ]:
      ensure => present,
  }

    file { '/etc/bird/bird.conf':  # TODO
        ensure  => present,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0440',
        content => template('birdlg/bird.conf.erb'),
    }
    file { '/etc/bird/bird6.conf':  # TODO
        ensure  => present,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0440',
        content => template('birdlg/bird6.conf.erb'),
    }

    service { 'bird':
        ensure    => running,
        subscribe => [
          File['/etc/bird/bird.conf'],
          File['/etc/bird/bird6.conf'],
          ],
        require   => Package['bird'],
    }

    file { "${install_dir}/lgproxy.cfg":
        ensure  => present,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0440',
        content => template('birdlg/lgproxy.cfg.erb'),
    }

    service::uwsgi { 'lgproxy':
        port            => $port,
        deployment_user => 'bird',   # TODO
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
