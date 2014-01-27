#
# == Class: openstack::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# [memcached_servers]
#   Use memcached instead of in-process cache.
#   Supply a list of memcached server IP's:Memcached Port.
#   (optional) Defaults to false.
#
# [api_bind_address]
#   IP address to use for binding Nova API's.
#   (optional) Defaults to '0.0.0.0'.
#
# [rabbit_hosts] An array of IP addresses or Virttual IP address for connecting to a RabbitMQ Cluster.
#   Optional. Defaults to false.
#
# [rabbit_cluster_nodes] An array of Rabbit Broker IP addresses within the Cluster.
#   Optional. Defaults to false.
#
# [neutron]
#   Specifies if nova should be configured to use neutron.
#   (optional) Defaults to false (indicating nova-networks should be used)
#
# [neutron_user_password]
#   password that nova uses to authenticate with neutron.
#
# [metadata_shared_secret] Secret used to authenticate between nova and the
#   neutron metadata services.
#   (Optional). Defaults to undef.
#
# [sql_idle_timeout]
#   Timeout for sql to reap connections.
#   (Optional) Defaults to '3600'.
#
# [use_syslog]
#   Use syslog for logging.
#   (Optional) Defaults to false.
#
# [log_facility]
#   Syslog facility to receive log lines.
#   (Optional) Defaults to LOG_USER.
#
# === Examples
#
# class { 'openstack::nova::controller':
#   public_address     => '192.168.1.1',
#   db_host            => '127.0.0.1',
#   rabbit_password    => 'changeme',
#   nova_user_password => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack::nova::controller (
  # Network Required
  $public_address,
  # Database Required
  $db_host,
  # Rabbit Required
  $rabbit_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  # Network
  $network_manager           = 'nova.network.manager.FlatDHCPManager',
  $network_config            = {},
  $floating_range            = false,
  $fixed_range               = '10.0.0.0/24',
  $admin_address             = $public_address,
  $internal_address          = $public_address,
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $multi_host                = false,
  $public_interface          = undef,
  $private_interface         = undef,
  # neutron
  $neutron                   = true,
  $neutron_user_password     = false,
  $metadata_shared_secret    = undef,
  $security_group_api        = 'neutron',
  # Nova
  $nova_admin_tenant_name    = 'services',
  $nova_admin_user           = 'nova',
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  $enabled_apis              = 'ec2,osapi_compute,metadata',
  $memcached_servers         = false,
  $api_bind_address          = '0.0.0.0',
  # Rabbit
  $rabbit_user               = 'openstack',
  $rabbit_virtual_host       = '/',
  $rabbit_hosts              = false,
  $rabbit_cluster_nodes      = false,
  # Database
  $db_type                   = 'mysql',
  $db_ssl                    = false,
  $db_ssl_ca                 = undef,
  $sql_idle_timeout          = '3600',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  $vncproxy_host             = undef,
  # Keystone
  $keystone_host             = '127.0.0.1',
  # Syslog
  $use_syslog                = false,
  $log_facility              = 'LOG_USER',
  # General
  $debug                     = false,
  $verbose                   = false,
  $enabled                   = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      if $db_ssl == true {
        $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}?ssl_ca=${db_ssl_ca}"
      } else {
        $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
      }
    }
    default: {
      fail("db_type ${db_type} is not supported")
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }
  if $vncproxy_host {
    $vncproxy_host_real = $vncproxy_host
  } else {
    $vncproxy_host_real = $public_address
  }

  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers
  $rabbit_connection = $internal_address

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid                 => $rabbit_user,
    password               => $rabbit_password,
    enabled                => $enabled,
    cluster_disk_nodes     => $rabbit_cluster_nodes,
    virtual_host           => $rabbit_virtual_host,
  }

  # Configure Nova
  class { 'nova':
    sql_connection       => $sql_connection,
    sql_idle_timeout     => $sql_idle_timeout,
    rabbit_userid        => $rabbit_user,
    rabbit_password      => $rabbit_password,
    rabbit_virtual_host  => $rabbit_virtual_host,
    image_service        => 'nova.image.glance.GlanceImageService',
    glance_api_servers   => $glance_connection,
    memcached_servers    => $memcached_servers,
    debug                => $debug,
    verbose              => $verbose,
    rabbit_host          => $rabbit_connection,
    rabbit_hosts         => $rabbit_hosts,
    use_syslog           => $use_syslog,
    log_facility         => $log_facility,
  }

  # Configure nova-api
  class { 'nova::api':
    enabled                              => $enabled,
    admin_tenant_name                    => $nova_admin_tenant_name,
    admin_user                           => $nova_admin_user,
    admin_password                       => $nova_user_password,
    enabled_apis                         => $enabled_apis,
    api_bind_address                     => $api_bind_address,
    auth_host                            => $keystone_host,
    neutron_metadata_proxy_shared_secret => $metadata_shared_secret,
  }


  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $neutron == false {
    # Configure nova-network
    if $multi_host {
      nova_config { 'DEFAULT/multi_host': value => true }
      $enable_network_service = true
    } else {
      nova_config { 'DEFAULT/multi_host': value => false }
      if $enabled {
        $enable_network_service = true
      } else {
        $enable_network_service = false
      }
    }

    if ! $private_interface  {
      fail('private interface must be set when nova networking is used')
    }
    if ! $public_interface  {
      fail('public interface must be set when nova networking is used')
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  } else {
    # Configure Nova for Neutron networking

    if ! $neutron_user_password {
      fail('neutron_user_password must be specified when neutron is configured')
    }

    class { 'nova::network::neutron':
      neutron_admin_password    => $neutron_user_password,
      neutron_auth_strategy     => 'keystone',
      neutron_url               => "http://${keystone_host}:9696",
      neutron_admin_tenant_name => 'services',
      neutron_admin_username    => 'neutron',
      neutron_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
      security_group_api        => $security_group_api,
    }
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => true }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth',
    'nova::conductor'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $vncproxy_host_real,
      enabled => $enabled,
    }
  }

}
