# == Class: netbox::base
#
# Installs Netbox
#
class netbox(
    $secret_key,
    $ldap_password,
    $db_password,
    $debug=false,
    $port=8001,
    $admins=false,
    $config_path = '/srv/deployment/netbox/deploy',
    $venv_path = '/srv/deployment/netbox/venv',
    $directory = '/srv/deployment/netbox/deploy/netbox',
    $ensure='present',

) {

  require_package('virtualenv', 'python3-dev',
                  'libldap2-dev',
                  'build-essential', 'python3-pip',
                  'libsasl2-dev', 'libssl-dev')


  file { "${directory}/netbox/netbox/configuration.py":
      ensure  => $ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      content => template('netbox/configuration.py.erb'),
  }

  file { "${directory}/netbox/netbox/ldap_config.py":
      ensure  => $ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      content => template('netbox/ldap_config.py.erb'),
  }

  service::uwsgi { 'netbox':
      port            => $port,
      deployment_user => 'deploy-librenms',
      config          => {
          need-plugins => 'python3',
          chdir        => "${directory}/netbox",
          venv         => $venv_path,
          wsgi         => "netbox.wsgi",
          vacuum       => true,
          http-socket  => "127.0.0.1:${port}",
          # T170189: make sure Python has a sane default encoding
          env          => [
              'LANG=C.UTF-8',
              'PYTHONENCODING=utf-8',
          ],
      },
      healthcheck_url => '/login/',
      icinga_check    => false,
      sudo_rules      => [
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-netbox restart',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-netbox start',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-netbox status',
          'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-netbox stop',
      ],
  }


}
