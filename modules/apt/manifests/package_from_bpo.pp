# SPDX-License-Identifier: Apache-2.0
#
# This define allows to install Debian packages from bpo.
#
# [*component*]
#  The component name on the repository, e.g. 'component/vp9',
#
# [*packages*]
#  An array of packages to install.
#  This parameter can also accept a Hash[String, String] which allows you to override
#  the ensure parameter and means you are able to create resources like the following
#  however this syntax should be used with caution as ties software updates to a git
#  commit to bump the version:
#
#    apt::package_bpo { 'foobar':
#      [..]
#      packages => { 'foo' => 'present', 'bar' => '1.1.7-1~bpo10+1'}
#    }
#
# [*distro*]
#  The Debian distribution providing backport packages to install.
#
# [*priority*]
#  An APT priority value. In our configuration, packages in the "main" component receive
#  a default priority of 1001. If you're adding a package from a component which isn't
#  in Debian or which is in a higher version than what's in Debian, you can simply use
#  the default value of 1001. If you're installing a package in a higher version than
#  what's in the "main" component of apt.wikimedia.org you should specify 1002.
#
#  [*ensure_packages*]
#   If true, the default, also install the packages array with ensure_packages($packages)
#
define apt::package_from_bpo(
    String[1]        $distro,
    Variant[Array[String],Hash[String,String]] $packages = [$title],
    Integer          $priority                           = 1001,
    Boolean          $ensure_packages                    = true,
) {
    include apt

    $exec_name = "exec-apt-get-update-${title}_${distro}-bpo"

    # the bpo archive content drastically changes from release to release
    # so make the distro a mandatory argument and be a NOOP if it mismatches
    if debian::codename::eq($distro) {
        $pkg_before = $ensure_packages ? {
            false => undef,
            default => $packages ? {
                Hash    => Package[$packages.keys],
                default => Package[$packages],
            }
        }

        $pinned_packages = $packages ? {
            Hash    => join($packages.keys, ' '),
            default => join($packages, ' '),
        }

        apt::pin { "apt_pin_${title}_${distro}-bpo":
            pin      => "release a=${distro}-backports",
            package  => $pinned_packages,
            priority => $priority,
            before   => $pkg_before,
            notify   => Exec[$exec_name],
        }

        exec { $exec_name:
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

        if $ensure_packages {
            if $packages =~ Hash {
                $packages.each |$pkg, $ensure| {
                    ensure_packages($pkg, {ensure => $ensure})
                }
            } else {
                ensure_packages($packages)
            }
        }

    } else {
        notify { "apt::package_from_bpo[${title}] did nothing! requested '${distro}-backports' in '${debian::codename()}'": }
    }
}
