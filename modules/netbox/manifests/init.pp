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
    String $secret_key,
    String $ldap_password,
    String $db_password,
    Boolean $debug=false,
    Stdlib::Port $port=8001,
    Stdlib::Unixpath $config_path = '/srv/deployment/netbox/deploy',
    Stdlib::Unixpath $venv_path = '/srv/deployment/netbox/venv',
    Stdlib::Unixpath $directory = '/srv/deployment/netbox/deploy/src',
    Stdlib::Unixpath $reports_path = '/srv/deployment/netbox-reports',
    Wmflib::Ensure $ensure='present',
    $ldap_server = undef,
    Optional[Stdlib::HTTPUrl] $swift_auth_url = undef,
    Optional[String] $swift_user = undef,
    Optional[String] $swift_key = undef,
    Optional[String] $swift_container = undef,
) {

  require_package('virtualenv', 'python3-pip')

  file { '/etc/netbox-configuration.py':
      ensure  => $ensure,
      owner   => 'deploy-librenms',
      group   => 'www-data',
      mode    => '0440',
      content => template('netbox/configuration.py.erb'),
      require => Scap::Target['netbox/deploy'],
      before  => Uwsgi::App['netbox'],
      notify  => Service['uwsgi-netbox'],
  }

  file { '/etc/netbox-ldap.py':
      ensure  => $ensure,
      owner   => 'deploy-librenms',
      group   => 'www-data',
      mode    => '0440',
      content => template('netbox/ldap_config.py.erb'),
      require => Scap::Target['netbox/deploy'],
      before  => Uwsgi::App['netbox'],
      notify  => Service['uwsgi-netbox'],
  }

  # Netbox is controlled via a custom systemd unit (uwsgi-netbox),
  # so avoid the generic uwsgi sysvinit script shipped in the package
  exec { 'mask_default_uwsgi':
      command => '/bin/systemctl mask uwsgi.service',
      creates => '/etc/systemd/system/uwsgi.service',
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
      core_limit      => '30G',
  }

  base::service_auto_restart { 'uwsgi-netbox': }

}
