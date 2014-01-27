#
# == Class: openstack::neutron
#
# Class to define neutron components for openstack. This class can
# be configured to provide all neutron related functionality.
#
# === Parameters
#
# [user_password]
#   Password used for authentication.
#  (required)
#
# [rabbit_password]
#   Password used to connect to rabbitmq
#   (required)
#
# [enabled]
#   state of the neutron services.
#   (optional) Defaults to true.
#
# [enable_server]
#   If the server should be installed.
#   (optional) Defaults to true.
#
# [enable_dhcp_agent]
#   Whether the dhcp agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_l3_agent]
#   Whether the l3 agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_metadata_agent]
#   Whether the metadata agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_ovs_agent]
#   Whether the ovs agent should be enabled.
#   (optional) Defaults to false.
#
# [bridge_uplinks]
#   OVS external bridge name and physical bridge interface tuple.
#   (optional) Defaults to [].
#
# [bridge_mappings]
#   Physical network name and OVS external bridge name tuple. Only needed for flat and VLAN networking.
#   (optional) Defaults to [].
#
# [auth_url]
#   Url used to contact the authentication service.
#   (optional) Defaults to 'http://localhost:35357/v2.0'.
#
# [shared_secret]
#    Shared secret used for the metadata service.
#    (optional) Defaults to false indicating the metadata service is not configured.
#
# [metadata_ip]
#    Ip address of metadata service.
#    (optional) Defaults to '127.0.0.1'.
#
# [db_password]
#   Password used to connect to neutron database.
#   (required)
#
# [db_type]
#   Type of database to use. Only accepts mysql at the moment.
#   (optional)
#
# [ovs_local_ip]
#   Ip address to use for tunnel endpoint.
#   Only required when tenant_network_type is 'gre'. No default.
#
# [ovs_enable_tunneling]
#    Whether ovs tunnels should be enabled.
#    (optional) Defaults to true.
#
# [allow_overlapping_ips]
#   Whether IP namespaces are in use
#   Optional. Defaults to 'false'.
#
# [tenant_network_type]
#   Type of network to allocate for tenant networks
#   Optional. Defualts to 'gre'.
#
# [network_vlan_ranges]
#   Comma-separated list of <physical_network>[:<vlan_min>:<vlan_max>]
#   tuples enumerating ranges of VLAN IDs on named physical networks
#   that are available for allocation.
#   Optional. Defaults to 'physnet1:1000:2000'.
#
# [firewall_driver]
#   Firewall driver to use.
#   (optional) Defaults to undef.
#
# [rabbit_user]
#   Name of rabbit user.
#   (optional) defaults to rabbit_user.
#
# [rabbit_host]
#   Host where rabbitmq is running.
#   (optional) 127.0.0.1
#
# [rabbit_hosts]
#   Enable/disable Qauntum to use rabbitmq mirrored queues.
#   Specifies an array of clustered rabbitmq brokers.
#   (optional) false
#
# [rabbit_virtual_host]
#   Virtual host to use for rabbitmq.
#   (optional) Defaults to '/'.
#
# [db_host]
#   Host where db is running.
#   (optional) Defaults to 127.0.0.1.
#
# [db_name]
#   Name of neutron database.
#   (optional) Defaults to neutron.
#
# [db_user]
#   User to connect to neutron database as.
#   (optional) Defaults to neutron.
#
# [bind_address]
#   Address neutron api server should bind to.
#  (optional) Defaults to 0.0.0.0.
#
# [sql_idle_timeout]
#   Timeout for sql to reap connections.
#   (optional) Defaults to '3600'.
#
# [keystone_host]
#   Host running keystone.
#   (optional) Defaults to 127.0.0.1.
#
# [use_syslog]
#   Use syslog for logging.
#   (optional) Default to false.
#
# [log_facility]
#   Syslog facility to receive log lines.
#   (optional) Default to LOG_USER.
#
# [verbose]
#   Enables verbose for neutron services.
#   (optional) Defaults to false.
#
# [debug]
#   Enables debug for neutron services.
#   (optional) Defaults to false.
#
# === Examples
#
# class { 'openstack::neutron':
#   db_password           => 'neutron_db_pass',
#   user_password         => 'keystone_user_pass',
#   rabbit_password       => 'neutron_rabbit_pass',
#   bridge_uplinks        => '[br-ex:eth0]',
#   bridge_mappings       => '[default:br-ex],
#   enable_ovs_agent      => true,
#   ovs_local_ip          => '10.10.10.10',
# }
#

class openstack::neutron (
  # Passwords
  $user_password,
  $rabbit_password,
  # enable or disable neutron
  $enabled                = true,
  $enable_server          = true,
  # Set DHCP/L3 Agents on Primary Controller
  $enable_dhcp_agent      = false,
  $enable_l3_agent        = false,
  $enable_metadata_agent  = false,
  $enable_ovs_agent       = false,
  # OVS settings
  $tenant_network_type    = 'gre',
  $network_vlan_ranges    = undef,
  $ovs_local_ip           = false,
  $ovs_enable_tunneling   = true,
  $allow_overlapping_ips  = false,
  $bridge_uplinks         = [],
  $bridge_mappings        = [],
  # rely on the default set in ovs
  $firewall_driver       = undef,
  # networking and Interface Information
  # Metadata configuration
  $shared_secret          = false,
  $metadata_ip            = '127.0.0.1',
  # Neutron Authentication Information
  $auth_url               = 'http://localhost:35357/v2.0',
  # Rabbit Information
  $rabbit_user            = 'rabbit_user',
  $rabbit_host            = '127.0.0.1',
  $rabbit_hosts           = false,
  $rabbit_virtual_host    = '/',
  # Database. Currently mysql is the only option.
  $db_type                = 'mysql',
  $db_password            = false,
  $db_host                = '127.0.0.1',
  $db_name                = 'neutron',
  $db_user                = 'neutron',
  $sql_idle_timeout       = '3600',
  # Plugin
  $core_plugin            = undef,
  # General
  $bind_address           = '0.0.0.0',
  $keystone_host          = '127.0.0.1',
  $use_syslog             = false,
  $log_facility           = 'LOG_USER',
  $verbose                = false,
  $debug                  = false,
) {

  class { '::neutron':
    enabled               => $enabled,
    core_plugin           => $core_plugin,
    bind_host             => $bind_address,
    allow_overlapping_ips => $allow_overlapping_ips,
    rabbit_host           => $rabbit_host,
    rabbit_hosts          => $rabbit_hosts,
    rabbit_virtual_host   => $rabbit_virtual_host,
    rabbit_user           => $rabbit_user,
    rabbit_password       => $rabbit_password,
    use_syslog            => $use_syslog,
    log_facility          => $log_facility,
    verbose               => $verbose,
    debug                 => $debug,
  }

  if $enable_server {
    if ! $db_password {
      fail('db password must be set when configuring a neutron server')
    }
    if ($db_type == 'mysql') {
      $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8"
    } else {
      fail("Unsupported db type: ${db_type}. Only mysql is currently supported.")
    }
    class { 'neutron::server':
      auth_host     => $keystone_host,
      auth_password => $user_password,
    }
    class { 'neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      sql_idle_timeout    => $sql_idle_timeout,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $network_vlan_ranges,
    }
  }

  if $enable_ovs_agent {
    class { 'neutron::agents::ovs':
      bridge_uplinks   => $bridge_uplinks,
      bridge_mappings  => $bridge_mappings,
      enable_tunneling => $ovs_enable_tunneling,
      local_ip         => $ovs_local_ip,
      firewall_driver  => $firewall_driver,
    }
  }

  if $enable_dhcp_agent {
    class { 'neutron::agents::dhcp':
      use_namespaces => true,
      debug          => $debug,
    }
  }
  if $enable_l3_agent {
    class { 'neutron::agents::l3':
      use_namespaces => true,
      debug          => $debug,
    }
  }

  if $enable_metadata_agent {
    if ! $shared_secret {
      fail('metadata_shared_secret parameter must be set when using metadata agent')
    }
    class { 'neutron::agents::metadata':
      auth_password  => $user_password,
      shared_secret  => $shared_secret,
      auth_url       => $auth_url,
      metadata_ip    => $metadata_ip,
      debug          => $debug,
    }
  }

}
