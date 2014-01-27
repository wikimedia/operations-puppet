# == Class: openstack::provision
#
# This class provides basic provisioning of a bare openstack
# deployment.  A non-admin user is created, an image is uploaded, and
# neutron networking is configured.  Once complete, it should be
# possible for the non-admin user to create a boot a VM that can be
# logged into via vnc (ssh may require extra configuration).
#
# This module is currently limited to targetting an all-in-one
# deployment for the following reasons:
#
#  - puppet-{keystone,glance,neutron} rely on their configuration files being
#    available on localhost which is not guaranteed for multi-host.
#
#  - the gateway configuration only supports a host that uses the same
#    interface for both management and tenant traffic.
#
#  - the gateway configuration makes the assumption that the local host is the
#    gateway host, which is not guaranteed to be true for multi-host.
#
# === Parameters
#
# Document parameters here.
#
# [*setup_ovs_bridge*]
#   Whether to configure the bridge specified by *public_bridge_name*
#   with the ip address of the subnet identified by
#   *public_subnet_name*.  This must be enabled if VMs are to be
#   reachable via floating ips.
#
# [*configure_tempest*]
#   Whether to use the provisioning details to configure Tempest, the
#   OpenStack integration test suite.
#
class openstack::provision(
  ## Keystone
  # non admin user
  $username                  = 'demo',
  $password                  = 'pass',
  $tenant_name               = 'demo',
  # another non-admin user
  $alt_username              = 'alt_demo',
  $alt_password              = 'pass',
  $alt_tenant_name           = 'alt_demo',
  # admin user
  $admin_username            = 'admin',
  $admin_password            = 'pass',
  $admin_tenant_name         = 'admin',

  ## Glance
  $image_name                = 'cirros',
  $image_source              = 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',
  $image_ssh_user            = 'cirros',

  ## Neutron
  $tenant_name               = 'demo',
  $public_network_name       = 'public',
  $public_subnet_name        = 'public_subnet',
  $floating_range            = '172.24.4.224/28',
  $private_network_name      = 'private',
  $private_subnet_name       = 'private_subnet',
  $fixed_range               = '10.0.0.0/24',
  $router_name               = 'router1',
  $setup_ovs_bridge          = false,
  $public_bridge_name        = 'br-ex',

  ## Tempest
  $configure_tempest         = false,

  $image_name_alt            = false,
  $image_source_alt          = false,
  $image_ssh_user_alt        = false,

  $identity_uri              = undef,
  $tempest_repo_uri          = 'git://github.com/openstack/tempest.git',
  $tempest_repo_revision     = undef,
  $tempest_clone_path        = '/var/lib/tempest',
  $tempest_clone_owner       = 'root',
  $setup_venv                = false,
  $resize_available          = undef,
  $change_password_available = undef,
  $cinder_available          = undef,
  $glance_available          = true,
  $heat_available            = undef,
  $horizon_available         = undef,
  $neutron_available         = true,
  $nova_available            = true,
  $swift_available           = undef
) {
  ## Users

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => true,
    description => 'default tenant',
  }
  keystone_user { $username:
    ensure      => present,
    enabled     => true,
    tenant      => $tenant_name,
    password    => $password,
  }

  keystone_tenant { $alt_tenant_name:
    ensure      => present,
    enabled     => true,
    description => 'alt tenant',
  }
  keystone_user { $alt_username:
    ensure      => present,
    enabled     => true,
    tenant      => $alt_tenant_name,
    password    => $alt_password,
  }

  ## Images

  glance_image { $image_name:
    ensure           => present,
    is_public        => 'yes',
    container_format => 'bare',
    disk_format      => 'qcow2',
    source           => $image_source,
  }

  # Support creation of a second glance image
  # distinct from the first, for tempest. It
  # doesn't need to be a different image, just
  # have a different name and ref in glance.
  if $image_name_alt {
    $image_name_alt_real = $image_name_alt
    if ! $image_source_alt {
      # Use the same source by default
      $image_source_alt_real = $image_source
    } else {
      $image_source_alt_real = $image_source_alt
    }

    if ! $image_ssh_user_alt {
      # Use the same user by default
      $image_alt_ssh_user_real = $image_ssh_user
    } else {
      $image_alt_ssh_user_real = $image_ssh_user_alt
    }

    glance_image { $image_name_alt:
      ensure           => present,
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => $image_source_alt_real,
    }
  } else {
    $image_name_alt_real = $image_name
  }

  ## Neutron

  if $neutron_available {
    $neutron_deps = [Neutron_network[$public_network_name]]

    neutron_network { $public_network_name:
      ensure          => present,
      router_external => true,
      tenant_name     => $admin_tenant_name,
    }
    neutron_subnet { $public_subnet_name:
      ensure          => 'present',
      cidr            => $floating_range,
      enable_dhcp     => false,
      network_name    => $public_network_name,
      tenant_name     => $admin_tenant_name,
    }
    neutron_network { $private_network_name:
      ensure      => present,
      tenant_name => $tenant_name,
    }
    neutron_subnet { $private_subnet_name:
      ensure       => present,
      cidr         => $fixed_range,
      network_name => $private_network_name,
      tenant_name  => $tenant_name,
    }
    # Tenant-owned router - assumes network namespace isolation
    neutron_router { $router_name:
      ensure               => present,
      tenant_name          => $tenant_name,
      gateway_network_name => $public_network_name,
      # A neutron_router resource must explicitly declare a dependency on
      # the first subnet of the gateway network.
      require              => Neutron_subnet[$public_subnet_name],
    }
    neutron_router_interface { "${router_name}:${private_subnet_name}":
      ensure => present,
    }

    if $setup_ovs_bridge {
      neutron_l3_ovs_bridge { $public_bridge_name:
        ensure      => present,
        subnet_name => $public_subnet_name,
      }
    }
  }
  else {
    $neutron_deps = []
    #TODO(marun): Provision for nova network
  }

  ## Tempest

  if $configure_tempest {
    $tempest_requires = concat([
                                Keystone_user[$username],
                                Keystone_user[$alt_username],
                                Glance_image[$image_name],
                                ], $neutron_deps)

    class { 'tempest':
      tempest_repo_uri          => $tempest_repo_uri,
      tempest_clone_path        => $tempest_clone_path,
      tempest_clone_owner       => $tempest_clone_owner,
      setup_venv                => $setup_venv,
      tempest_repo_revision     => $tempest_repo_revision,
      image_name                => $image_name,
      image_name_alt            => $image_name_alt_real,
      image_ssh_user            => $image_ssh_user,
      image_alt_ssh_user        => $image_alt_ssh_user_real,
      identity_uri              => $identity_uri,
      username                  => $username,
      password                  => $password,
      tenant_name               => $tenant_name,
      alt_username              => $alt_username,
      alt_password              => $alt_password,
      alt_tenant_name           => $alt_tenant_name,
      admin_username            => $admin_username,
      admin_password            => $admin_password,
      admin_tenant_name         => $admin_tenant_name,
      public_network_name       => $public_network_name,
      resize_available          => $resize_available,
      change_password_available => $change_password_available,
      cinder_available          => $cinder_available,
      glance_available          => $glance_available,
      heat_available            => $heat_available,
      horizon_available         => $horizon_available,
      neutron_available         => $neutron_available,
      nova_available            => $nova_available,
      swift_available           => $swift_available,
      require                   => $tempest_requires,
    }
  }

}
