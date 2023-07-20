# SPDX-License-Identifier: Apache-2.0
# == Define: apparmor::profile
#
# Populates and loads an appamor profile on the including host
# == Parameters
# [*name*]
# Name of the profile, will be used as a filename

# [*path*]
# The path in the puppet repo where this profile lives in

# [*ensure*]
# Standard ensure

# [*directory*]
# Directory where the profile will be stored on the host, defaults to
# /etc/apparmor.d
define apparmor::profile(
    String $source,
    Wmflib::Ensure $ensure = 'present',
    Optional[Stdlib::UnixPath] $directory = '/etc/apparmor.d',
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

    $path = "${directory}/${name}"
    file { $path:
        ensure => $ensure,
        source => $source,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        notify => Exec["load apparmor profile ${name}"],
    }

    $parser_command = $ensure ? {
      absent  => "/usr/sbin/apparmor_parser -R ${path}",
      default => "/usr/sbin/apparmor_parser -a ${path}",
    }
    exec { "load apparmor profile ${name}":
      command     => $parser_command,
      refreshonly => true,
    }
}
