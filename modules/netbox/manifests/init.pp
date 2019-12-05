# == Class: netbox::base
#
# Installs Netbox
#
# === Parameters
#
# [*service_hostname*]
#  The external hostname for this service.
#
# [*secret_key*]
#   Django secret key
#
# [*ldap_password*]
#   Password of the LDAP bind user
#
# [*db_host*]
#    The database host address.
#
# [*db_password*]
#   Password of the database user
#
# [*db_port*]
#    The port on which the database is listening.
#
# [*db_user*]
#    The user to connect to the database as.
#
# [*debug*]
#   Turn on django debugging
#
# [*port*]
#   Port the python app listen on
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
# [*extras_path*]
#   The path which the extras repository will be cloned to
#
# [*ensure*]
#   installs/removes config files
#
# [*ldap_server*]
#   The LDAP server to specify in the configuration
#
# [*include_ldap*]
#   Enable/disable LDAP authentication
#
# [*swift_auth_url*]
#   The authentication URL to be used for image storage.
#   Setting this to undef will prevent swift form being configured.
#
# [*swift_user*]
#   The user to connect to SWIFT for image storage as.
#
# [*swift_key*]
#   The key for the above user.
#
# [*swift_container*]
#   The name of the SWIFT container to store images to
#
# [*swift_ca*]
#   The path to the CA that signs the SWIFT api endpoint.
#
# [*redis_host*]
#   The hostname of the Redis instance to use for caching.
#
# [*redis_port*]
#   The port of the Redis instance to use for caching.
#
# [*redis_password*]
#   The password to authenticate to Redis with.
#
# [*redis_database*]
#   The database to select in the Redis host.
#
class netbox(
    Stdlib::Fqdn $service_hostname,
    String $secret_key,
    String $ldap_password,
    Stdlib::Fqdn $db_host,
    String $db_password,
    Stdlib::Port $db_port = 5432,
    String $db_user = 'netbox',
    Boolean $debug=false,
    Stdlib::Port $port=8001,
    Stdlib::Unixpath $config_path = '/srv/deployment/netbox/deploy',
    Stdlib::Unixpath $venv_path = '/srv/deployment/netbox/venv',
    Stdlib::Unixpath $directory = '/srv/deployment/netbox/deploy/src',
    Stdlib::Unixpath $extras_path = '/srv/deployment/netbox-extras',
    Wmflib::Ensure $ensure='present',
    Optional[Stdlib::Fqdn] $ldap_server = undef,
    Boolean $include_ldap = false,
    Optional[Stdlib::HTTPUrl] $swift_auth_url = undef,
    Optional[String] $swift_user = undef,
    Optional[String] $swift_key = undef,
    Optional[String] $swift_container = undef,
    Optional[String] $swift_url_key = undef,
    Optional[Stdlib::Unixpath] $swift_ca = undef,
    Stdlib::Fqdn $redis_host = undef,
    Stdlib::Port $redis_port = undef,
    String $redis_password = undef,
    Integer $redis_database = 0,
) {
    require_package('virtualenv', 'python3-pip', 'python3-pynetbox')

    user { 'netbox':
        ensure  => $ensure,
        comment => 'This is the global owner for all Netbox things.',
        system  => true,
        home    => '/var/lib/netbox',
        shell   => '/bin/bash'
    }

    file { '/etc/netbox/configuration.py':
        ensure  => $ensure,
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('netbox/configuration.py.erb'),
        require => [Scap::Target['netbox/deploy'],
                    User['netbox']],
        before  => Uwsgi::App['netbox'],
        notify  => Service['uwsgi-netbox'],
    }

    if $include_ldap {
        file { '/etc/netbox/ldap.py':
            ensure  => $ensure,
            owner   => 'netbox',
            group   => 'www-data',
            mode    => '0440',
            content => template('netbox/ldap_config.py.erb'),
            require => Scap::Target['netbox/deploy'],
            before  => Uwsgi::App['netbox'],
            notify  => Service['uwsgi-netbox'],
        }
    }

    # Netbox is controlled via a custom systemd unit (uwsgi-netbox),
    # so avoid the generic uwsgi sysvinit script shipped in the package
    exec { 'mask_default_uwsgi':
        command => '/bin/systemctl mask uwsgi.service',
        creates => '/etc/systemd/system/uwsgi.service',
    }

  $base_uwsgi_environ=[
      'LANG=C.UTF-8',
      'PYTHONENCODING=utf-8',
  ]
  if $swift_ca {
      $uwsgi_environ = concat($base_uwsgi_environ, "REQUESTS_CA_BUNDLE=${swift_ca}")
  }
  else {
      $uwsgi_environ = $base_uwsgi_environ
  }
  service::uwsgi { 'netbox':
      port            => $port,
      deployment_user => 'netbox',
      config          => {
          need-plugins => 'python3',
          chdir        => "${directory}/netbox",
          venv         => $venv_path,
          wsgi         => 'netbox.wsgi',
          vacuum       => true,
          http-socket  => "127.0.0.1:${port}",
          # T170189: make sure Python has a sane default encoding
          env          => $uwsgi_environ,
          max-requests => 300,
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
