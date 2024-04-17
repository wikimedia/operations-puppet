# SPDX-License-Identifier: Apache-2.0
# == Define: apparmor::profile
#
# Populates and loads an appamor profile on the including host
# == Parameters
# [*name*]
# Name of the profile, will be used as a filename (defailts to $title)
#
# [*source*]
# The actual profile content (as string)
#
# [*ensure*]
# Standard ensure
#
# [*directory*]
# Directory where the profile will be stored on the host, defaults to
# /etc/apparmor.d. Profiles in other directories will not be loaded
# automatically on reboot/apparmor restarts.
define apparmor::profile (
    String $source,
    Wmflib::Ensure $ensure = 'present',
    Stdlib::UnixPath $directory = '/etc/apparmor.d',
) {
    require apparmor

    if !defined(File[$directory]) {
        file { $directory:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0440',
        }
    }

    # The profile filename is the name of this resource, slashes replaced with dots
    # as per the convention in apparmor(7)
    $path = "${directory}/${regsubst($name, '/', '.', 'G')}"
    file { $path:
        ensure => $ensure,
        source => $source,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        notify => Exec["load apparmor profile ${name}"],
    }

    $parser_command = $ensure ? {
      # --remove will unload the profile if it exists, it still requires ${path} to exist
      'absent' => "/usr/sbin/apparmor_parser --remove ${path}",
      # --replace will load the profile if it doesn't exist yet, or replace if it does
      default  => "/usr/sbin/apparmor_parser --replace ${path}",
    }
    exec { "load apparmor profile ${name}":
      command     => $parser_command,
      refreshonly => true,
    }
}
