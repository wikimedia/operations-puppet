# == Class: birdlg::lg_frontend
#
# Install Bird LG - frontend
#
# Install lg, the frontend part of BirdLG, that talks to backend instances
#
# === Parameters
#
# [*install_dir*]
#   Directory to install lg
#
# [*session_key*]
#   Python unique session key
#
# [*domain*]
#   Domain under which the frontend will look for backends instances
#   See lg.cfg for more details
#
# [*port*]
#   Port for BirdLG frontend to listen for Apache reverse proxy
#
class birdlg::lg_frontend(
    $secret_key,
    $domain,
    $install_dir='/srv/deployment/birdlg/',
    $port='5001',
) {

  require_package([
          'python-flask',
          'python-dnspython',
          'python-pydot',
          'python-memcache',
          'graphviz',
      ])

  file { "${install_dir}/lg.cfg":
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0440',
      content => template('birdlg/lg.cfg.erb'),
  }

  service::uwsgi { 'lg':
      port            => $port,
      deployment_user => 'deploy-librenms',
      config          => {
          need-plugins => 'python',
          chdir        => $install_dir,
          wsgi         => 'lg.wsgi',
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
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lg restart',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lg start',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lg status',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-lg stop',
      ],
  }

}
