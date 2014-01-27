#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file (default) or Swift
#
# === Parameters
#
# [user_password] Password for glance auth user. Required.
# [db_password] Password for glance DB. Required.
# [db_host] Host where DB resides. Required.
# [keystone_host] Host whre keystone is running. Optional. Defaults to '127.0.0.1'
# [sql_idle_timeout] Timeout for SQL to reap connections. Optional. Defaults to '3600'
# [registry_host] Address used by API to find the Registry service. Optional. Defaults to '0.0.0.0'
# [bind_host] Address for binding API and Registry services. Optional. Defaults to '0.0.0.0'
# [db_type] Type of sql databse to use. Optional. Defaults to 'mysql'
# [db_ssl] Boolean whether to use SSL for database. Defaults to false.
# [db_ssl_ca] If db_ssl is true, this is used in the connection to define the CA. Default undef.
# [db_user] Name of glance DB user. Optional. Defaults to 'glance'
# [db_name] Name of glance DB. Optional. Defaults to 'glance'
# [backend] Backends used to store images.  Defaults to file.
# [rbd_store_user] The RBD store user name.
# [rbd_store_pool] The RBD pool name to store images.
# [swift_store_user] The Swift service user account. Defaults to false.
# [swift_store_key]  The Swift service user password Defaults to false.
# [swift_store_auth_addres] The URL where the Swift auth service lives. Defaults to "http://${keystone_host}:5000/v2.0/"
# [verbose] Log verbosely. Optional. Defaults to false.
# [debug] Log at a debug-level. Optional. Defaults to false.
# [use_syslog] Use syslog for logging. Optional. Defaults to false.
# [syslog_facility] Syslog facility to receive log lines. Optional. Defaults to LOG_USER.
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
#
# === Example
#
# class { 'openstack::glance':
#   user_password => 'changeme',
#   db_password   => 'changeme',
#   db_host       => '127.0.0.1',
# }

class openstack::glance (
  $user_password,
  $db_password,
  $db_host                  = '127.0.0.1',
  $keystone_host            = '127.0.0.1',
  $sql_idle_timeout         = '3600',
  $registry_host            = '0.0.0.0',
  $bind_host                = '0.0.0.0',
  $db_type                  = 'mysql',
  $db_ssl                   = false,
  $db_ssl_ca                = undef,
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $backend                  = 'file',
  $swift_store_user         = false,
  $swift_store_key          = false,
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $rbd_store_user           = undef,
  $rbd_store_pool           = 'images',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $enabled                  = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      if $db_ssl == true {
        $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
      } else {
        $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
      }
    }
    default: {
      fail("db_type ${db_type} is not supported")
    }
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $debug,
    registry_host     => $registry_host,
    bind_host         => $bind_host,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    use_syslog        => $use_syslog,
    log_facility      => $log_facility,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $debug,
    bind_host         => $bind_host,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    use_syslog        => $use_syslog,
    log_facility      => $log_facility,
    enabled           => $enabled,
  }

  # Configure file storage backend
  if($backend == 'swift') {

    if ! $swift_store_user {
      fail('swift_store_user must be set when configuring swift as the glance backend')
    }
    if ! $swift_store_key {
      fail('swift_store_key must be set when configuring swift as the glance backend')
    }

    class { 'glance::backend::swift':
      swift_store_user                    => $swift_store_user,
      swift_store_key                     => $swift_store_key,
      swift_store_auth_address            => $swift_store_auth_address,
      swift_store_create_container_on_put => true,
    }
  } elsif($backend == 'file') {
  # Configure file storage backend
    class { 'glance::backend::file': }
  } elsif($backend == 'rbd') {
    class { 'glance::backend::rbd':
      rbd_store_user => $rbd_store_user,
      rbd_store_pool => $rbd_store_pool,
    }
  } else {
    fail("Unsupported backend ${backend}")
  }

}
