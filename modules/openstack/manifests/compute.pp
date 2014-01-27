#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# [purge_nova_config]
#   Whether unmanaged nova.conf entries should be purged.
#   (optional) Defaults to false.
#
# [neutron_firewall_driver]
#   Driver used to implement Neutron firewalling.
#   (optional) Defaults to false.
#
# [ovs_enable_tunneling]
#   Enable/disable the Neutron OVS GRE tunneling networking mode.
#   Optional.  Defaults to true.
#
# [rabbit_hosts] An array of IP addresses or Virttual IP address for connecting to a RabbitMQ Cluster.
#   Optional. Defaults to false.
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
# class { 'openstack::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
# }

class openstack::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password,
  # DB
  $nova_db_password,
  $db_host                       = '127.0.0.1',
  # Nova Database
  $nova_db_user                  = 'nova',
  $nova_db_name                  = 'nova',
  # Network
  $public_interface              = undef,
  $private_interface             = undef,
  $fixed_range                   = undef,
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  $enabled_apis                  = 'ec2,osapi_compute,metadata',
  # Neutron
  $neutron                       = true,
  $neutron_user_password         = false,
  $neutron_admin_tenant_name     = 'services',
  $neutron_admin_user            = 'neutron',
  $enable_ovs_agent              = true,
  $enable_l3_agent               = false,
  $enable_dhcp_agent             = false,
  $neutron_auth_url              = 'http://127.0.0.1:35357/v2.0',
  $keystone_host                 = '127.0.0.1',
  $neutron_host                  = '127.0.0.1',
  $ovs_enable_tunneling          = true,
  $ovs_local_ip                  = false,
  $neutron_firewall_driver       = false,
  $bridge_mappings               = undef,
  $bridge_uplinks                = undef,
  $security_group_api            = 'neutron',
  # Nova
  $nova_admin_tenant_name        = 'services',
  $nova_admin_user               = 'nova',
  $purge_nova_config             = false,
  $libvirt_vif_driver            = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
  # Rabbit
  $rabbit_host                   = '127.0.0.1',
  $rabbit_hosts                  = false,
  $rabbit_user                   = 'openstack',
  $rabbit_virtual_host           = '/',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  # cinder / volumes
  $manage_volumes                = true,
  $cinder_volume_driver          = 'iscsi',
  $cinder_db_password            = false,
  $cinder_db_user                = 'cinder',
  $cinder_db_name                = 'cinder',
  $volume_group                  = 'cinder-volumes',
  $iscsi_ip_address              = '127.0.0.1',
  $setup_test_volume             = false,
  $cinder_rbd_user               = 'volumes',
  $cinder_rbd_pool               = 'volumes',
  $cinder_rbd_secret_uuid        = false,
  # General
  $migration_support             = false,
  $verbose                       = false,
  $force_config_drive            = false,
  $use_syslog                    = false,
  $log_facility                  = 'LOG_USER',
  $enabled                       = true
) {

  if $ovs_local_ip {
    $ovs_local_ip_real = $ovs_local_ip
  } else {
    $ovs_local_ip_real = $internal_address
  }

  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address
  }


  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
    }
  }

  $nova_sql_connection = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_name}"

  class { 'nova':
    sql_connection      => $nova_sql_connection,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_api_servers,
    verbose             => $verbose,
    rabbit_host         => $rabbit_host,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    use_syslog          => $use_syslog,
    log_facility        => $log_facility,
  }

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
    force_config_drive            => $force_config_drive,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if ! $neutron {

    if ! $fixed_range {
      fail('Must specify the fixed range when using nova-networks')
    }

    if $multi_host {
      include keystone::python
      nova_config {
        'DEFAULT/multi_host':      value => true;
        'DEFAULT/send_arp_for_ha': value => true;
      }
      if ! $public_interface {
        fail('public_interface must be defined for multi host compute nodes')
      }
      $enable_network_service = true
      class { 'nova::api':
        enabled           => true,
        admin_tenant_name => $nova_admin_tenant_name,
        admin_user        => $nova_admin_user,
        admin_password    => $nova_user_password,
        enabled_apis      => $enabled_apis,
      }
    } else {
      $enable_network_service = false
      nova_config {
        'DEFAULT/multi_host':      value => false;
        'DEFAULT/send_arp_for_ha': value => false;
      }
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => false,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => false,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  } else {

    if ! $neutron_user_password {
      fail('neutron_user_password must be set when neutron is configured')
    }
    if ! $keystone_host {
      fail('keystone_host must be configured when neutron is installed')
    }

    class { 'openstack::neutron':
      # Database
      db_host              => $db_host,
      # Networking
      ovs_local_ip         => $ovs_local_ip_real,
      # Rabbit
      rabbit_host          => $rabbit_host,
      rabbit_hosts         => $rabbit_hosts,
      rabbit_user          => $rabbit_user,
      rabbit_password      => $rabbit_password,
      # Neutron OVS
      enable_ovs_agent     => $enable_ovs_agent,
      ovs_enable_tunneling => $ovs_enable_tunneling,
      firewall_driver      => $neutron_firewall_driver,
      # Neutron L3 Agent
      enable_l3_agent      => $enable_l3_agent,
      enable_dhcp_agent    => $enable_dhcp_agent,
      auth_url             => $neutron_auth_url,
      user_password        => $neutron_user_password,
      # Keystone
      keystone_host        => $keystone_host,
      # General
      enabled              => $enabled,
      enable_server        => false,
      verbose              => $verbose,
      bridge_mappings      => $bridge_mappings,
      bridge_uplinks       => $bridge_uplinks,
      use_syslog           => $use_syslog,
      log_facility         => $log_facility,
    }

    class { 'nova::compute::neutron':
      libvirt_vif_driver => $libvirt_vif_driver,
    }

    # Configures nova.conf entries applicable to Neutron.
    class { 'nova::network::neutron':
      neutron_admin_password    => $neutron_user_password,
      neutron_auth_strategy     => 'keystone',
      neutron_url               => "http://${neutron_host}:9696",
      neutron_admin_username    => $neutron_admin_user,
      neutron_admin_tenant_name => $neutron_admin_tenant_name,
      neutron_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
      security_group_api        => $security_group_api
    }

  }

  if $manage_volumes {

    if ! $cinder_db_password {
      fail('cinder_db_password must be set when cinder is being configured')
    }

    $cinder_sql_connection = "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_name}"

    class { 'openstack::cinder::storage':
      sql_connection      => $cinder_sql_connection,
      rabbit_password     => $rabbit_password,
      rabbit_userid       => $rabbit_user,
      rabbit_host         => $rabbit_host,
      rabbit_hosts        => $rabbit_hosts,
      rabbit_virtual_host => $rabbit_virtual_host,
      volume_group        => $volume_group,
      iscsi_ip_address    => $iscsi_ip_address,
      enabled             => $enabled,
      verbose             => $verbose,
      setup_test_volume   => $setup_test_volume,
      rbd_user            => $cinder_rbd_user,
      rbd_pool            => $cinder_rbd_pool,
      rbd_secret_uuid     => $cinder_rbd_secret_uuid,
      volume_driver       => $cinder_volume_driver,
      use_syslog          => $use_syslog,
      log_facility        => $log_facility,
    }

    # set in nova::api
    if ! defined(Nova_config['DEFAULT/volume_api_class']) {
      nova_config { 'DEFAULT/volume_api_class': value => 'nova.volume.cinder.API' }
    }
  }

}
