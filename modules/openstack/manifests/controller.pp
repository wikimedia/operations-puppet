#
# This can be used to build out the simplest openstack controller
#
# === Parameters
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [public_protocol] Protocol used by public endpoints. Defaults to 'http'
# [token_format] Format keystone uses for tokens. Optional. Defaults to PKI.
#   Supports PKI and UUID.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [sql_idle_timeout] Timeout for sql to reap connections.
#   (Optional) Defaults to undef.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [keystone_bind_address] Address that keystone api service should bind to.
#   Optional. Defaults to '0.0.0.0'.
# [keystone_token_driver] Driver to use for managing tokens.
#   Optional.  Defaults to 'keystone.token.backends.sql.Token'
# [glance_registry_host] Address used by Glance API to find the Glance Registry service.
#   Optional. Defaults to '0.0.0.0'.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
# [nova_memcached_servers]   (array) List of memcached servers for use with nova.
#    (optional) Defaults to false.  Values should be hostname:port format.
#
# [purge_nova_config]
#   Whether unmanaged nova.conf entries should be purged.
#   (optional) Defaults to false.
#
# [nova_bind_address]
#   IP address to use for binding Nova API's.
#   (optional) Defualts to '0.0.0.0'.
#
# [rabbit_password] Rabbit password.
# [rabbit_user] Rabbit User. Optional. Defaults to openstack.
# [rabbit_host] IP address to connect to the RabbitMQ Broker. Optional. Defaults to '127.0.0.1'.
# [rabbit_hosts] An array of IP addresses or Virttual IP address for connecting to a RabbitMQ Cluster.
#   Optional. Defaults to false.
# [rabbit_cluster_nodes] An array of Rabbit Broker IP addresses within the Cluster.
#   Optional. Defaults to false.
# [rabbit_virtual_host] Rabbit virtual host path for Nova. Defaults to '/'.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [debug] Whether to log services at debug.
# [verbose] Whether to log services at verbose.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies, …
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [horizon]             (bool) is horizon installed. Defaults to: true
# [neutron]             (bool) is neutron installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
#
# [ovs_enable_tunneling]
#   Enable/disable the Neutron OVS GRE tunneling networking mode.
#   Optional.  Defaults to true.
#
# [metadata_shared_secret]
#   Shared secret used by nova and neutron to authenticate metadata.
#   (optional) Defaults to false.
#
# [physical_network]
#   Unique name of the physical network used by the Neutron OVS Agent.
#   All physical networks listed are available for flat and VLAN
#   provider network creation.
#
# [tenant_network_type]
#   Type of network to allocate for tenant networks
#   Optional. Defualts to 'gre'.
#
# [network_vlan_ranges]
#   Comma-separated list of <physical_network>[:<vlan_min>:<vlan_max>]
#   tuples enumerating ranges of VLAN IDs on named physical networks
#   that are available for allocation.  Only applicable when tenant_network_type
#   parameter is set to 'vlan'.
#   Optional. Defaults to 'physnet1:
#
# [firewall_driver]
#   Driver used to implement firewall rules.
#   (optional) Defaults to 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'.
#
# [neutron_auth_url]
#   Url used to neutron to contact the authentication service.
#  (optional) Default to http://127.0.0.1:35357/v2.0.
#
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [enabled] Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. Defaults to true.
# [swift]
#   Whether or not to configure keystone for swift authorization.
#   (Optional). Defaults to false.
#
# [swift_user_password]
#   Auth password for swift.
#   (Optional) Defaults to false. Required if swift is set to true.
#
# [swift_public_address]
#   The swift public endpoint address used to populate the keystone service catalog.
#   (optional). Defaults to false.
#
# [swift_internal_address]
#   The swift internal endpoint address used to populate the keystone service catalog.
#   (optional). Defaults to false.
#
# [swift_admin_address]
#   The swift admin endpoint address used to populate the keystone service catalog.
#   (optional). Defaults to false.
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
# class { 'openstack::controller':
#   public_address       => '192.168.0.3',
#   mysql_root_password  => 'changeme',
#   allowed_hosts        => ['127.0.0.%', '192.168.1.%'],
#   admin_email          => 'my_email@mw.com',
#   admin_password       => 'my_admin_password',
#   keystone_db_password => 'changeme',
#   keystone_admin_token => '12345',
#   glance_db_password   => 'changeme',
#   glance_user_password => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_user_password   => 'changeme',
#   secret_key           => 'dummy_secret_key',
# }
#
class openstack::controller (
  # Required Network
  $public_address,
  $admin_email,
  # required password
  $admin_password,
  $rabbit_password,
  $keystone_db_password,
  $keystone_admin_token,
  $glance_db_password,
  $glance_user_password,
  $nova_db_password,
  $nova_user_password,
  $nova_memcached_servers  = false,
  $secret_key,
  $mysql_root_password,
  # cinder and neutron password are not required b/c they are
  # optional. Not sure what to do about this.
  $neutron_user_password   = false,
  $neutron_db_password     = false,
  $neutron_core_plugin     = undef,
  $cinder_user_password    = false,
  $cinder_db_password      = false,
  $swift_user_password     = false,
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $sql_idle_timeout        = undef,
  $allowed_hosts           = '%',
  $mysql_ssl               = false,
  $mysql_ca                = undef,
  $mysql_cert              = undef,
  $mysql_key               = undef,
  # Keystone
  $keystone_host           = '127.0.0.1',
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $keystone_bind_address   = '0.0.0.0',
  $region                  = 'RegionOne',
  $public_protocol         = 'http',
  $keystone_token_driver   = 'keystone.token.backends.sql.Token',
  $token_format            = 'PKI',
  # Glance
  $glance_registry_host    = '0.0.0.0',
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  $glance_api_servers      = undef,
  $glance_backend          = 'file',
  $glance_rbd_store_user   = undef,
  $glance_rbd_store_pool   = undef,
  # Glance Swift Backend
  $swift_store_user        = 'swift_store_user',
  $swift_store_key         = 'swift_store_key',
  # Nova
  $nova_admin_tenant_name  = 'services',
  $nova_admin_user         = 'nova',
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = false,
  $enabled_apis            = 'ec2,osapi_compute,metadata',
  $nova_bind_address       = '0.0.0.0',
  # Nova Networking
  $public_interface        = false,
  $private_interface       = false,
  $internal_address        = false,
  $admin_address           = false,
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  # Rabbit
  $rabbit_host             = '127.0.0.1',
  $rabbit_hosts            = false,
  $rabbit_cluster_nodes    = false,
  $rabbit_user             = 'openstack',
  $rabbit_virtual_host     = '/',
  # Horizon
  $horizon                 = true,
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $horizon_app_links       = undef,
  # VNC
  $vnc_enabled             = true,
  $vncproxy_host           = false,
  # General
  $debug                   = false,
  $verbose                 = false,
  # cinder
  # if the cinder management components should be installed
  $cinder                  = true,
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  $cinder_bind_address     = '0.0.0.0',
  $manage_volumes          = false,
  $volume_group            = 'cinder-volumes',
  $setup_test_volume       = false,
  $iscsi_ip_address        = '127.0.0.1',
  # Neutron
  $neutron                 = true,
  $physical_network        = 'default',
  $tenant_network_type     = 'gre',
  $ovs_enable_tunneling    = true,
  $allow_overlapping_ips   = false,
  $ovs_local_ip            = false,
  $network_vlan_ranges     = undef,
  $bridge_interface        = undef,
  $external_bridge_name    = 'br-ex',
  $bridge_uplinks          = undef,
  $bridge_mappings         = undef,
  $enable_ovs_agent        = true,
  $enable_dhcp_agent       = true,
  $enable_l3_agent         = true,
  $enable_metadata_agent   = true,
  $metadata_shared_secret  = false,
  $firewall_driver         = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
  $neutron_db_user         = 'neutron',
  $neutron_db_name         = 'neutron',
  $neutron_auth_url        = 'http://127.0.0.1:35357/v2.0',
  $enable_neutron_server   = true,
  $security_group_api      = 'neutron',
  # swift
  $swift                   = false,
  $swift_public_address    = false,
  $swift_internal_address  = false,
  $swift_admin_address     = false,
  # Syslog
  $use_syslog              = false,
  $log_facility            = 'LOG_USER',
  $enabled                 = true
) {

  if $ovs_local_ip {
    $ovs_local_ip_real = $ovs_local_ip
  } else {
    $ovs_local_ip_real = $internal_address
  }

  if $internal_address {
    $internal_address_real = $internal_address
  } else {
    $internal_address_real = $public_address
  }
  if $admin_address {
    $admin_address_real = $admin_address
  } else {
    $admin_address_real = $internal_address_real
  }
  if $vncproxy_host {
    $vncproxy_host_real = $vncproxy_host
  } else {
    $vncproxy_host_real = $public_address
  }

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']
  Class['openstack::db::mysql'] -> Class['openstack::nova::controller']

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
    }
    class { 'openstack::db::mysql':
      mysql_root_password    => $mysql_root_password,
      mysql_bind_address     => $mysql_bind_address,
      mysql_account_security => $mysql_account_security,
      mysql_ssl              => $mysql_ssl,
      mysql_ca               => $mysql_ca,
      mysql_cert             => $mysql_cert,
      mysql_key              => $mysql_key,
      keystone_db_user       => $keystone_db_user,
      keystone_db_password   => $keystone_db_password,
      keystone_db_dbname     => $keystone_db_dbname,
      glance_db_user         => $glance_db_user,
      glance_db_password     => $glance_db_password,
      glance_db_dbname       => $glance_db_dbname,
      nova_db_user           => $nova_db_user,
      nova_db_password       => $nova_db_password,
      nova_db_dbname         => $nova_db_dbname,
      cinder                 => $cinder,
      cinder_db_user         => $cinder_db_user,
      cinder_db_password     => $cinder_db_password,
      cinder_db_dbname       => $cinder_db_dbname,
      neutron                => $neutron,
      neutron_db_user        => $neutron_db_user,
      neutron_db_password    => $neutron_db_password,
      neutron_db_dbname      => $neutron_db_name,
      allowed_hosts          => $allowed_hosts,
      enabled                => $enabled,
    }
  } else {
    fail("Unsupported db : ${db_type}")
  }

  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    debug                     => $debug,
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => $db_host,
    db_password               => $keystone_db_password,
    db_name                   => $keystone_db_dbname,
    db_user                   => $keystone_db_user,
    db_ssl                    => $mysql_ssl,
    db_ssl_ca                 => $mysql_ca,
    idle_timeout              => $sql_idle_timeout,
    admin_token               => $keystone_admin_token,
    admin_tenant              => $keystone_admin_tenant,
    admin_email               => $admin_email,
    admin_password            => $admin_password,
    token_driver              => $keystone_token_driver,
    public_address            => $public_address,
    public_protocol           => $public_protocol,
    token_format              => $token_format,
    internal_address          => $internal_address_real,
    admin_address             => $admin_address_real,
    region                    => $region,
    glance_user_password      => $glance_user_password,
    glance_internal_address   => $internal_address_real,
    glance_admin_address      => $admin_address_real,
    nova_user_password        => $nova_user_password,
    nova_internal_address     => $internal_address_real,
    nova_admin_address        => $admin_address_real,
    cinder                    => $cinder,
    cinder_user_password      => $cinder_user_password,
    cinder_internal_address   => $internal_address_real,
    cinder_admin_address      => $admin_address_real,
    neutron                   => $neutron,
    neutron_user_password     => $neutron_user_password,
    neutron_internal_address  => $internal_address_real,
    neutron_admin_address     => $admin_address_real,
    swift                     => $swift,
    swift_user_password       => $swift_user_password,
    swift_public_address      => $swift_public_address,
    swift_internal_address    => $swift_internal_address,
    swift_admin_address       => $swift_admin_address,
    enabled                   => $enabled,
    bind_host                 => $keystone_bind_address,
    use_syslog                => $use_syslog,
    log_facility              => $log_facility,
  }


  ######## BEGIN GLANCE ##########
  class { 'openstack::glance':
    debug            => $debug,
    verbose          => $verbose,
    db_type          => $db_type,
    db_host          => $db_host,
    db_ssl           => $mysql_ssl,
    db_ssl_ca        => $mysql_ca,
    sql_idle_timeout => $sql_idle_timeout,
    keystone_host    => $keystone_host,
    registry_host    => $glance_registry_host,
    db_user          => $glance_db_user,
    db_name          => $glance_db_dbname,
    db_password      => $glance_db_password,
    user_password    => $glance_user_password,
    backend          => $glance_backend,
    swift_store_user => $swift_store_user,
    swift_store_key  => $swift_store_key,
    rbd_store_user   => $glance_rbd_store_user,
    rbd_store_pool   => $glance_rbd_store_pool,
    use_syslog       => $use_syslog,
    log_facility     => $log_facility,
    enabled          => $enabled,
  }

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  class { 'openstack::nova::controller':
    # Database
    db_host                 => $db_host,
    sql_idle_timeout        => $sql_idle_timeout,
    # Network
    network_manager         => $network_manager,
    network_config          => $network_config,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    public_address          => $public_address,
    admin_address           => $admin_address,
    internal_address        => $internal_address_real,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    create_networks         => $create_networks,
    num_networks            => $num_networks,
    multi_host              => $multi_host,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    # Neutron
    neutron                 => $neutron,
    neutron_user_password   => $neutron_user_password,
    metadata_shared_secret  => $metadata_shared_secret,
    security_group_api      => $security_group_api,
    # Nova
    nova_admin_tenant_name  => $nova_admin_tenant_name,
    nova_admin_user         => $nova_admin_user,
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    memcached_servers       => $nova_memcached_servers,
    enabled_apis            => $enabled_apis,
    api_bind_address        => $nova_bind_address,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    rabbit_hosts            => $rabbit_hosts,
    rabbit_cluster_nodes    => $rabbit_cluster_nodes,
    rabbit_virtual_host     => $rabbit_virtual_host,
    # Glance
    glance_api_servers      => $glance_api_servers,
    # Keystone
    keystone_host           => $keystone_host,
    # VNC
    vnc_enabled             => $vnc_enabled,
    vncproxy_host           => $vncproxy_host_real,
    # Syslog
    use_syslog              => $use_syslog,
    log_facility            => $log_facility,
    # General
    debug                   => $debug,
    verbose                 => $verbose,
    enabled                 => $enabled,
  }

  ######### Neutron Controller Services ########
  if ($neutron) {

    if ! $neutron_user_password {
      fail('neutron_user_password must be set when configuring neutron')
    }

    if ! $neutron_db_password {
      fail('neutron_db_password must be set when configuring neutron')
    }

    if ! $bridge_interface {
      fail('bridge_interface must be set when configuring neutron')
    }

    if ! $bridge_uplinks {
      $bridge_uplinks_real = ["${external_bridge_name}:${bridge_interface}"]
    } else {
      $bridge_uplinks_real = $bridge_uplinks
    }

    if ! $bridge_mappings {
      $bridge_mappings_real  = ["${physical_network}:${external_bridge_name}"]
    } else {
      $bridge_mappings_real  = $bridge_mappings
    }

    class { 'openstack::neutron':
      # Database
      db_host               => $db_host,
      sql_idle_timeout      => $sql_idle_timeout,
      # Rabbit
      rabbit_host           => $rabbit_host,
      rabbit_user           => $rabbit_user,
      rabbit_password       => $rabbit_password,
      rabbit_hosts          => $rabbit_hosts,
      rabbit_virtual_host   => $rabbit_virtual_host,
      # Neutron OVS
      tenant_network_type   => $tenant_network_type,
      network_vlan_ranges   => $network_vlan_ranges,
      ovs_enable_tunneling  => $ovs_enable_tunneling,
      allow_overlapping_ips => $allow_overlapping_ips,
      ovs_local_ip          => $ovs_local_ip_real,
      bridge_uplinks        => $bridge_uplinks_real,
      bridge_mappings       => $bridge_mappings_real,
      enable_ovs_agent      => $enable_ovs_agent,
      firewall_driver       => $firewall_driver,
      # Database
      db_name               => $neutron_db_name,
      db_user               => $neutron_db_user,
      db_password           => $neutron_db_password,
      # Plugin
      core_plugin           => $neutron_core_plugin,
      # Neutron agents
      enable_dhcp_agent     => $enable_dhcp_agent,
      enable_l3_agent       => $enable_l3_agent,
      enable_metadata_agent => $enable_metadata_agent,
      auth_url              => $neutron_auth_url,
      user_password         => $neutron_user_password,
      shared_secret         => $metadata_shared_secret,
      # Keystone
      keystone_host         => $keystone_host,
      # Syslog
      use_syslog            => $use_syslog,
      log_facility          => $log_facility,
      # General
      enabled               => $enabled,
      enable_server         => $enable_neutron_server,
      debug                 => $debug,
      verbose               => $verbose,
    }
  }

  ######### Cinder Controller Services ########
  if ($cinder) {

    if ! $cinder_db_password {
      fail('Must set cinder db password when setting up a cinder controller')
    }

    if ! $cinder_user_password {
      fail('Must set cinder user password when setting up a cinder controller')
    }

    class { 'openstack::cinder::all':
      bind_host          => $cinder_bind_address,
      sql_idle_timeout   => $sql_idle_timeout,
      keystone_auth_host => $keystone_host,
      keystone_password  => $cinder_user_password,
      rabbit_userid      => $rabbit_user,
      rabbit_password    => $rabbit_password,
      rabbit_host        => $rabbit_host,
      rabbit_hosts       => $rabbit_hosts,
      db_password        => $cinder_db_password,
      db_dbname          => $cinder_db_dbname,
      db_user            => $cinder_db_user,
      db_type            => $db_type,
      db_host            => $db_host,
      manage_volumes     => $manage_volumes,
      volume_group       => $volume_group,
      setup_test_volume  => $setup_test_volume,
      iscsi_ip_address   => $iscsi_ip_address,
      use_syslog         => $use_syslog,
      log_facility       => $log_facility,
      enabled            => $enabled,
      debug              => $debug,
      verbose            => $verbose
    }
  }

  ######## Horizon ########
  if ($horizon) {
    class { 'openstack::horizon':
      secret_key        => $secret_key,
      cache_server_ip   => $cache_server_ip,
      cache_server_port => $cache_server_port,
      horizon_app_links => $horizon_app_links,
      keystone_host     => $keystone_host,
    }
  }

}
