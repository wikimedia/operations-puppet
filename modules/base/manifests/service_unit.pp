# == Base::service_unit ==
#
# DEPRECATED! New uses of this will fail CI.
# Use systemd::service instead
#
# Allows defining services and their corresponding init scripts in a
# init-system agnostic way on Debian derivatives.
#
# We prefer convention over configuration, so this define will require
# you to respect those in order to work.
#
# === Parameters ===
#
# [*ensure*]
#  Is the usual metaparameter, defaults to present. Valid values are 'present'
#  and 'absent'.
#  Note that the underlying service is also controlled by this metaparameter
#  (unless $declare_service is false), in other words 'present' will
#  ensure => running and conversely 'absent' will ensure => stopped.
#
# [*systemd*]
#  String. If it is a non-empty string, the content will be used as the content
#  of the custom systemd service file.
#
# [*systemd_override*]
#  String. If it is a non-empty string, make the resource use a systemd unit provided
#  by a Debian package, while applying an override file with site-
#  specific changes.
#
# [*refresh*]
#  Boolean - tells puppet if a change in the config should notify the service
#  directly
#
# [*declare_service*]
#  Boolean - tells puppet if a service {} stanza is required or not
#
# [*mask*]
#  Boolean - tells puppet if a systemd service should be masked
#
# [*service_params*]
#  An hash of parameters that we want to apply to the service resource
#
# === Example ===
#
# A init-agnostic class that runs apache, with its own init scripts
# (please, don't do it at home!)
#
# class foo {
#     base::service_unit { 'apache2':
#         ensure          => present,
#         systemd         => systemd_template('apache2'),
#         service_params  => {
#             hasrestart => true,
#             restart => '/usr/sbin/service apache2 restart'
#         }
#     }
# }

define base::service_unit (
  Wmflib::Ensure $ensure             = present,
  Optional[String] $systemd          = undef,
  Optional[String] $systemd_override = undef,
  Boolean $refresh                   = true,
  Boolean $declare_service           = true,
  Boolean $mask                      = false,
  Hash $service_params               = {},
) {

  $unit_content = pick($systemd_override, $systemd, false)

  # we assume init scripts are templated
  if $unit_content {
    $path = $systemd_override ? {
      undef   => "/lib/systemd/system/${name}.service",
      default => "/etc/systemd/system/${name}.service.d/puppet-override.conf",
    }
    $systemd_mask_path = "/etc/systemd/system/${name}.service"

    if $systemd_override {
      file { "/etc/systemd/system/${name}.service.d":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => File[$path],
      }
    }

    file { $path:
      ensure  => $ensure,
      content => $unit_content,
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
    }

    if $mask {
      file { $systemd_mask_path:
        ensure => 'link',
        target => '/dev/null',
        owner  => 'root',
        group  => 'root',
      }
    }

    if $declare_service {
      if $refresh {
        File[$path] ~> Service[$name]
      } else {
        File[$path] -> Service[$name]
      }
    }

    exec { "systemd reload for ${name}":
      refreshonly => true,
      command     => '/bin/systemctl daemon-reload',
      subscribe   => File[$path],
    }
    if $declare_service {
      Exec["systemd reload for ${name}"] -> Service[$name]
    }
  }

  if $declare_service {
    $enable = $ensure ? {
      'present' => true,
      default   => false,
    }
    $base_params = {
      ensure   => stdlib::ensure($ensure, 'service'),
      enable   => $enable,
    }
    $params = merge($base_params, $service_params)
    ensure_resource('service', $name, $params)
  }
}
