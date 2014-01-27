#
# Class that performs a basic openstack all in one installation.
#
# === Parameters
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [keystone_bind_address] Address that keystone api service should bind to.
#   Optional. Defaults to '0.0.0.0'.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
#
# [purge_nova_config]
#   Whether unmanaged nova.conf entries should be purged.
#   (optional) Defaults to false.
#
# [rabbit_password] Rabbit password.
# [rabbit_user] Rabbit User. Optional. Defaults to openstack.
# [rabbit_virtual_host] Rabbit virtual host path for Nova. Defaults to '/'.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [debug] (bool) Whether to log services at debug. Default to: false.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [verbose] Whether to log services at verbose.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [horizon]             (bool) is horizon installed. Defaults to: true
# [neutron]             (bool) is neutron installed
# [network_vlan_ranges] array of vlan_start:vlan_stop groups
# [bridge_mappings]     array of physical_newtork:l2_start:l2end groups
# [bridge_uplinks]      array of bridge_name:bridge_interface groups
# [tenant_network_type] vlan, gre, etc.
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [metadata_shared_secret]
#   Shared secret used by nova and neutron to authenticate metadata.
#   (optional) Defaults to false.
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
#
# === Examples
#
# class { 'openstack::all':
#   public_address         => '192.168.0.3',
#   public_interface       => eth0,
#   private_interface      => eth1,
#   internal_address       => '192.168.1.3',
#   mysql_root_password    => 'changeme',
#   allowed_hosts          => ['127.0.0.%', '192.168.1.%'],
#   admin_email            => 'my_email@mw.com',
#   admin_password         => 'my_admin_password',
#   keystone_db_password   => 'changeme',
#   keystone_admin_token   => '12345',
#   glance_db_password     => 'changeme',
#   glance_user_password   => 'changeme',
#   nova_db_password       => 'changeme',
#   nova_user_password     => 'changeme',
#   secret_key             => 'dummy_secret_key',
#   nova_user_password     => 'changeme',
#   nova_db_password       => 'changeme',
#   glance_user_password   => 'changeme',
#   glance_db_password     => 'changeme',
#   cinder_user_password   => 'changeme',
#   cinder_db_password     => 'changeme',
#   keystone_db_password   => 'changeme',
#   admin_password         => 'changeme',
#   rabbit_password        => 'changeme',
#   keystone_admin_token   => 'changeme',
#   neutron_user_password  => 'changeme',
#   neutron_db_password    => 'changeme',
#   secret_key             => 'dummy_secret_key',
#   bridge_interface       => 'eth0',
#   metadata_shared_secret => 'shared_md_secret',
#   enable_ovs_agent       => true,
# }
#
class openstack::all (
  # Required Network
  $public_address,
  $public_interface,
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
  $secret_key,
  $mysql_root_password,
  # cinder and neutron password are not required b/c they are
  # optional. Not sure what to do about this.
  $neutron_user_password   = false,
  $neutron_db_password     = false,
  $cinder_user_password    = false,
  $cinder_db_password      = false,
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $allowed_hosts           = '%',
  $charset                 = 'latin1',
  # Keystone
  $keystone_host           = '127.0.0.1',
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $keystone_bind_address   = '0.0.0.0',
  $region                  = 'RegionOne',
  # Glance
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  $glance_api_servers      = undef,
  $glance_backend          = 'file',
  # Glance Swift Backend
  $swift_store_user        = 'swift_store_user',
  $swift_store_key         = 'swift_store_key',
  # Glance RBD Backend
  $glance_rbd_user         = 'images',
  $glance_rbd_pool         = 'images',
  # Nova
  $nova_admin_tenant_name  = 'services',
  $nova_admin_user         = 'nova',
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = false,
  $libvirt_vif_driver      = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
  $enabled_apis            = 'ec2,osapi_compute,metadata',
  $force_config_drive      = false,
  # Virtualization
  $libvirt_type            = 'kvm',
  $migration_support       = false,
  # Nova Networking
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
  $vncserver_listen        = false,
  # cinder
  # if the cinder management components should be installed
  $cinder                  = true,
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  $cinder_bind_address     = '0.0.0.0',
  $manage_volumes          = true,
  $setup_test_volume       = false,
  $volume_group            = 'cinder-volumes',
  $iscsi_ip_address        = '127.0.0.1',
  $cinder_volume_driver    = 'iscsi',
  $cinder_rbd_user         = 'volumes',
  $cinder_rbd_pool         = 'volumes',
  $cinder_rbd_secret_uuid  = false,
  # Neutron
  $neutron                 = true,
  $bridge_interface        = undef,
  $external_bridge_name    = 'br-ex',
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
  $ovs_enable_tunneling    = true,
  $ovs_local_ip            = false,
  $network_vlan_ranges     = undef,
  $bridge_mappings         = undef,
  $bridge_uplinks          = undef,
  $tenant_network_type     = 'gre',
  # General
  $debug                   = false,
  $verbose                 = false,
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
  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address_real
  }
  if $glance_api_servers {
    $glance_api_servers_real = $glance_api_servers
  } else {
    $glance_api_servers_real = "${internal_address_real}:9292"
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
      charset                => $charset,
      enabled                => $enabled,
    }
  } else {
    fail("Unsupported db : ${db_type}")
  }

  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose               => $verbose,
    db_type               => $db_type,
    db_host               => $db_host,
    db_password           => $keystone_db_password,
    db_name               => $keystone_db_dbname,
    db_user               => $keystone_db_user,
    debug                 => $debug,
    admin_token           => $keystone_admin_token,
    admin_tenant          => $keystone_admin_tenant,
    admin_email           => $admin_email,
    admin_password        => $admin_password,
    public_address        => $public_address,
    internal_address      => $internal_address_real,
    admin_address         => $admin_address_real,
    region                => $region,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    cinder                => $cinder,
    cinder_user_password  => $cinder_user_password,
    neutron               => $neutron,
    neutron_user_password => $neutron_user_password,
    enabled               => $enabled,
    bind_host             => $keystone_bind_address,
  }


  ######## BEGIN GLANCE ##########
  class { 'openstack::glance':
    verbose          => $verbose,
    db_type          => $db_type,
    db_host          => $db_host,
    debug            => $debug,
    keystone_host    => $keystone_host,
    db_user          => $glance_db_user,
    db_name          => $glance_db_dbname,
    db_password      => $glance_db_password,
    user_password    => $glance_user_password,
    backend          => $glance_backend,
    swift_store_user => $swift_store_user,
    swift_store_key  => $swift_store_key,
    rbd_store_user   => $glance_rbd_user,
    rbd_store_pool   => $glance_rbd_pool,
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

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address_real,
    vncproxy_host                 => $vncproxy_host_real,
    force_config_drive            => $force_config_drive
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  class { 'openstack::nova::controller':
    # Database
    db_host                 => $db_host,
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
    # Nova
    nova_admin_tenant_name  => $nova_admin_tenant_name,
    nova_admin_user         => $nova_admin_user,
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    enabled_apis            => $enabled_apis,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    rabbit_virtual_host     => $rabbit_virtual_host,
    # Glance
    glance_api_servers      => $glance_api_servers_real,
    # VNC
    vnc_enabled             => $vnc_enabled,
    vncproxy_host           => $vncproxy_host_real,
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

    if ! $bridge_mappings {
      $bridge_mappings_real = ["default:${external_bridge_name}"]
    } else {
      $bridge_mappings_real = $bridge_mappings
    }

    if ! $bridge_uplinks {
      $bridge_uplinks_real = ["${external_bridge_name}:${bridge_interface}"]
    } else {
      $bridge_uplinks_real = $bridge_uplinks
    }

    class { 'openstack::neutron':
      debug                 => $debug,
      # Database
      db_host               => $db_host,
      # Rabbit
      rabbit_host           => $rabbit_host,
      rabbit_user           => $rabbit_user,
      rabbit_password       => $rabbit_password,
      rabbit_virtual_host   => $rabbit_virtual_host,
      # Neutron OVS
      ovs_enable_tunneling  => $ovs_enable_tunneling,
      ovs_local_ip          => $ovs_local_ip_real,
      bridge_uplinks        => $bridge_uplinks_real,
      bridge_mappings       => $bridge_mappings_real,
      enable_ovs_agent      => $enable_ovs_agent,
      firewall_driver       => $firewall_driver,
      tenant_network_type   => $tenant_network_type,
      network_vlan_ranges   => $network_vlan_ranges,
      # Database
      db_name               => $neutron_db_name,
      db_user               => $neutron_db_user,
      db_password           => $neutron_db_password,
      # Neutron agents
      enable_dhcp_agent     => $enable_dhcp_agent,
      enable_l3_agent       => $enable_l3_agent,
      enable_metadata_agent => $enable_metadata_agent,
      auth_url              => $neutron_auth_url,
      user_password         => $neutron_user_password,
      shared_secret         => $metadata_shared_secret,
      # Keystone
      keystone_host         => $keystone_host,
      # General
      enabled               => $enabled,
      enable_server         => $enable_neutron_server,
      verbose               => $verbose,
    }
    class { 'nova::compute::neutron':
      libvirt_vif_driver => $libvirt_vif_driver,
    }
  } else {

    if ! $fixed_range {
      fail('Must specify the fixed range when using nova-networks')
    }

    if $multi_host {
      include keystone::python
      nova_config {
        'DEFAULT/send_arp_for_ha': value => true;
      }
    } else {
      nova_config {
        'DEFAULT/send_arp_for_ha': value => false;
      }
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
      debug              => $debug,
      keystone_auth_host => $keystone_host,
      keystone_password  => $cinder_user_password,
      rabbit_userid      => $rabbit_user,
      rabbit_password    => $rabbit_password,
      rabbit_host        => $rabbit_host,
      db_password        => $cinder_db_password,
      db_dbname          => $cinder_db_dbname,
      db_user            => $cinder_db_user,
      db_type            => $db_type,
      db_host            => $db_host,
      iscsi_ip_address   => $iscsi_ip_address,
      volume_driver      => $cinder_volume_driver,
      rbd_user           => $cinder_rbd_user,
      rbd_pool           => $cinder_rbd_pool,
      rbd_secret_uuid    => $cinder_rbd_secret_uuid,
      setup_test_volume  => $setup_test_volume,
      manage_volumes     => $manage_volumes,
      volume_group       => $volume_group,
      verbose            => $verbose
    }

    # set in nova::api
    if ! defined(Nova_config['DEFAULT/volume_api_class']) {
      nova_config { 'DEFAULT/volume_api_class': value => 'nova.volume.cinder.API' }
    }
  }

  ######## Horizon ########
  if ($horizon) {
    class { 'openstack::horizon':
      secret_key        => $secret_key,
      cache_server_ip   => $cache_server_ip,
      cache_server_port => $cache_server_port,
      horizon_app_links => $horizon_app_links,
    }
  }
}
