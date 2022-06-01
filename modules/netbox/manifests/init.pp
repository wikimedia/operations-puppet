# SPDX-License-Identifier: Apache-2.0
# @summary Installs Netbox
# @param service_hostname The external hostname for this service.
# @param discovery_name The fqdn name used internally
# @param secret_key Django secret key
# @param ldap_password Password of the LDAP bind user
# @param db_host The database host address.
# @param db_password Password of the database user
# @param db_port The port on which the database is listening.
# @param db_user The user to connect to the database as.
# @param debug Turn on django debugging
# @param port Port the python app listen on
# @param config_path Path to the deploy directory
# @param venv_path Path to the python virtualenv
# @param directory Path to the netbox app
# @param extras_path The path which the extras repository will be cloned to
# @param scap_repo The repo to use for scap deploys
# @param ensure installs/removes config files
# @param local_redis_port The port (as a string) that the required local Redis instance should listen on
# @param local_redis_maxmem The amount of memory in bytes that the local Redis instance should use
# @param ldap_server The LDAP server to specify in the configuration
# @param enable_ldap Enable/disable LDAP authentication
# @param authentication_provider which auth provider to use ldap/cas
# @param swift_auth_url The authentication URL to be used for image storage.
# @param http_proxy the proxy for netbox to use for outbound connections
# @param cas_rename_attributes hash of attributes to rename
# @param cas_group_attribute_mapping hash of cas attributes to map
# @param cas_group_mapping hash of nextbox group mappings
# @param cas_group_required list of required groups
# @param cas_server_url The cas service url
# @param cas_username_attribute The cas username attribute
# @param swift_user The user to connect to SWIFT for image storage as.
# @param swift_key The key for the above user.
# @param swift_container The name of the SWIFT container to store images to
# @param swift_url_key The swift url key
# @param ca_certs The path to the CA certificates that signs internal certs.
#
class netbox(
    Stdlib::Fqdn                  $service_hostname,
    String                        $secret_key,
    String                        $ldap_password,
    Stdlib::Fqdn                  $db_host,
    String                        $db_password,
    Stdlib::Fqdn                  $discovery_name              = $facts['networking']['fqdn'],
    Wmflib::Ensure                $ensure                      = 'present',
    Stdlib::Port                  $db_port                     = 5432,
    String                        $db_user                     = 'netbox',
    Boolean                       $debug                       = false,
    Stdlib::Port                  $port                        = 8001,
    Stdlib::Unixpath              $config_path                 = '/srv/deployment/netbox/deploy',
    Stdlib::Unixpath              $venv_path                   = '/srv/deployment/netbox/venv',
    Stdlib::Unixpath              $directory                   = '/srv/deployment/netbox/deploy/src',
    Stdlib::Unixpath              $extras_path                 = '/srv/deployment/netbox-extras',
    String                        $scap_repo                   = 'netbox/deploy',
    Stdlib::Port                  $local_redis_port            = 6380,
    Integer                       $local_redis_maxmem          = 1610612736,  # 1.5Gb
    Optional[Stdlib::Fqdn]        $ldap_server                 = undef,
    Boolean                       $enable_ldap                 = false,
    Optional[Enum['ldap', 'cas']] $authentication_provider     = undef,
    Optional[Stdlib::HTTPUrl]     $swift_auth_url              = undef,
    Optional[Stdlib::HTTPUrl]     $http_proxy                  = undef,
    # Cas specific config
    Hash[String, String]          $cas_rename_attributes       = {},
    Hash[String, Array]           $cas_group_attribute_mapping = {},
    Hash[String, Array]           $cas_group_mapping           = {},
    Array                         $cas_group_required          = [],
    Stdlib::HTTPSUrl              $cas_server_url              = 'https://cas.example.org',
    Optional[String]              $cas_username_attribute      = undef,
    # Swift specific config
    Optional[String]              $swift_user                  = undef,
    Optional[String]              $swift_key                   = undef,
    Optional[String]              $swift_container             = undef,
    Optional[String]              $swift_url_key               = undef,
    Optional[Stdlib::Unixpath]    $ca_certs                    = undef,
) {
    ensure_packages(['virtualenv', 'python3-pip', 'python3-pynetbox'])
    $home_path = '/var/lib/netbox'

    file { $home_path:
        ensure => directory,
        owner  => 'netbox',
        group  => 'netbox',
        mode   => '0755',
    }

    # Configure REDIS to be memory-only (no persistance) and to only accept local
    # connections
    redis::instance { String($local_redis_port):  # cast as int's are not valid titles
      settings => {
        # below setting prevents persistance
        save                     => '""',
        bind                     => '127.0.0.1 ::1',
        maxmemory                => $local_redis_maxmem,
        maxmemory_policy         => 'volatile-lru',
        maxmemory_samples        => 5,
        lazyfree-lazy-eviction   => 'yes',
        lazyfree-lazy-expire     => 'yes',
        lazyfree-lazy-server-del => 'yes',
        lua-time-limit           => 5000,
        databases                => 3,
        protected-mode           => 'yes',
        dbfilename               => '""',
        appendfilename           => '""',
      },
    }
    prometheus::redis_exporter { String($local_redis_port): }

    user { 'netbox':
        ensure  => $ensure,
        comment => 'This is the global owner for all Netbox things.',
        system  => true,
        home    => $home_path,
        shell   => '/bin/bash',
    }

    file { '/etc/netbox/configuration.py':
        ensure  => $ensure,
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('netbox/configuration.py.erb'),
        require => Scap::Target[$scap_repo],
        before  => Uwsgi::App['netbox'],
        notify  => [Service['uwsgi-netbox'], Service['rq-netbox']],
    }

    file { '/etc/netbox/ldap.py':
        ensure  => $ensure,
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('netbox/ldap_config.py.erb'),
        require => Scap::Target[$scap_repo],
        before  => Uwsgi::App['netbox'],
        notify  => [Service['uwsgi-netbox'], Service['rq-netbox']],
    }
    file { '/etc/netbox/cas_configuration.py':
        ensure  => $ensure,
        owner   => 'netbox',
        group   => 'www-data',
        mode    => '0440',
        content => template('netbox/cas_configuration.py.erb'),
        require => Scap::Target[$scap_repo],
        before  => Uwsgi::App['netbox'],
        notify  => [Service['uwsgi-netbox'], Service['rq-netbox']],
    }

    # Netbox is controlled via a custom systemd unit (uwsgi-netbox),
    # so avoid the generic uwsgi sysvinit script shipped in the package
    exec { 'mask_default_uwsgi':
        command => '/bin/systemctl mask uwsgi.service',
        creates => '/etc/systemd/system/uwsgi.service',
    }

  $uwsgi_environ=[
      'LANG=C.UTF-8',
      'PYTHONENCODING=utf-8',
      "REQUESTS_CA_BUNDLE=${ca_certs}",
  ]
  service::uwsgi { 'netbox':
      port            => $port,
      deployment_user => 'netbox',
      repo            => $scap_repo,
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
          'ALL=(root) NOPASSWD: /usr/sbin/service rq-netbox restart',
          'ALL=(root) NOPASSWD: /usr/sbin/service rq-netbox start',
          'ALL=(root) NOPASSWD: /usr/sbin/service rq-netbox status',
          'ALL=(root) NOPASSWD: /usr/sbin/service rq-netbox stop',

      ],
      core_limit      => '30G',
  }

  systemd::service { 'rq-netbox':
    ensure  => $ensure,
    content => file('netbox/rq-netbox.service'),
  }

  profile::auto_restarts::service { 'uwsgi-netbox': }
  profile::auto_restarts::service { 'rq-netbox': }

}
