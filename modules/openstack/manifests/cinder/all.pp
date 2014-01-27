class openstack::cinder::all(
  $rabbit_password,
  $keystone_password,
  $db_password,
  $rpc_backend              = 'cinder.openstack.common.rpc.impl_kombu',
  $keystone_tenant          = 'services',
  $keystone_enabled         = true,
  $keystone_user            = 'cinder',
  $keystone_auth_host       = 'localhost',
  $keystone_auth_port       = '35357',
  $keystone_auth_protocol   = 'http',
  $keystone_service_port    = '5000',
  $rabbit_userid            = 'openstack',
  $rabbit_host              = '127.0.0.1',
  $rabbit_hosts             =  undef,
  $rabbit_port              = '5672',
  $rabbit_virtual_host      = '/',
  # Database. Currently mysql is the only option.
  $db_type                  = 'mysql',
  $db_user                  = 'cinder',
  $db_host                  = '127.0.0.1',
  $db_dbname                = 'cinder',
  $sql_idle_timeout         = '3600',
  $package_ensure           = present,
  $bind_host                = '0.0.0.0',
  $api_paste_config         = '/etc/cinder/api-paste.ini',
  $scheduler_driver         = 'cinder.scheduler.simple.SimpleScheduler',
  $enabled                  = true,
  $volume_group             = 'cinder-volumes',
  $volume_driver            = 'iscsi',
  $iscsi_ip_address         = '127.0.0.1',
  $rbd_user                 = 'volumes',
  $rbd_pool                 = 'volumes',
  $rbd_secret_uuid          = false,
  $setup_test_volume        = false,
  $manage_volumes           = true,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $debug                    = false,
  $verbose                  = false
) {

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_dbname}?charset=utf8"
  } else {
    fail("Unsupported db_type ${db_type}")
  }

  class {'::cinder':
    sql_connection      => $sql_connection,
    sql_idle_timeout    => $sql_idle_timeout,
    rpc_backend         => $rpc_backend,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    package_ensure      => $package_ensure,
    api_paste_config    => $api_paste_config,
    use_syslog          => $use_syslog,
    log_facility        => $log_facility,
    debug               => $debug,
    verbose             => $verbose,
  }

  class {'::cinder::api':
    keystone_password       => $keystone_password,
    keystone_enabled        => $keystone_enabled,
    keystone_user           => $keystone_user,
    keystone_auth_host      => $keystone_auth_host,
    keystone_auth_port      => $keystone_auth_port,
    keystone_auth_protocol  => $keystone_auth_protocol,
    service_port            => $keystone_service_port,
    package_ensure          => $package_ensure,
    bind_host               => $bind_host,
    enabled                 => $enabled,
  }

  class {'::cinder::scheduler':
    scheduler_driver       => $scheduler_driver,
    package_ensure         => $package_ensure,
    enabled                => $enabled,
  }

  if $manage_volumes {
    class {'::cinder::volume':
      package_ensure => $package_ensure,
      enabled        => $enabled,
    }

    if $volume_driver {
      if $volume_driver == 'iscsi' {
        class { 'cinder::volume::iscsi':
          iscsi_ip_address => $iscsi_ip_address,
          volume_group     => $volume_group,
        }
        if $setup_test_volume {
          class {'::cinder::setup_test_volume':
            volume_name => $volume_group,
          }
        }
      } elsif $volume_driver == 'rbd' {
        class { 'cinder::volume::rbd':
          rbd_pool        => $rbd_pool,
          rbd_user        => $rbd_user,
          rbd_secret_uuid => $rbd_secret_uuid,
        }
      } else {
        warning("Unsupported volume driver: ${volume_driver}, make sure you are configuring this yourself")
      }
    }
  }
}
