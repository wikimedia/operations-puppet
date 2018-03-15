# == Class: netbox::base
#
# Installs Netbox
#
# === Parameters
#
# [*secret_key*]
#   Django secret key
#
# [*ldap_password*]
#   Password of the LDAP bind used
#
# [*db_password*]
#   Password of the database user netbox
#
# [*debug*]
#   Turn on django debugging
#
# [*port*]
#   Port the pyton app listen on
#
# [*admins*]
#   Name and email of the django admin contacts
#
# [*config_path*]
#   Path to the deploy directory
#
# [*venv_path*]
#   Path to the python virtualenv
#
# [*directory*]
#   Path to the netbox app
#
# [*ensure*]
#   installs/removes config files
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

  require_package('virtualenv', 'python3-pip')


  file { "${directory}/netbox/netbox/configuration.py":
      ensure  => $ensure,
      owner   => 'deploy-librenms',
      group   => 'www-data',
      mode    => '0440',
      content => template('netbox/configuration.py.erb'),
      require => Scap::Target['netbox/deploy'],
      before  => Uwsgi::App['netbox'],
  }

  file { "${directory}/netbox/netbox/ldap_config.py":
      ensure  => $ensure,
      owner   => 'deploy-librenms',
      group   => 'www-data',
      mode    => '0440',
      content => template('netbox/ldap_config.py.erb'),
      require => Scap::Target['netbox/deploy'],
      before  => Uwsgi::App['netbox'],
  }

  service::uwsgi { 'netbox':
      port            => $port,
      deployment_user => 'deploy-librenms',
      config          => {
          need-plugins => 'python3',
          chdir        => "${directory}/netbox",
          venv         => $venv_path,
          wsgi         => 'netbox.wsgi',
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
