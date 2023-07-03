# SPDX-License-Identifier: Apache-2.0
define apt::package_from_bpo(
    String[1]        $distro,
    Array[String[1]] $packages        = [$title],
    Integer          $priority        = 1001,
    Boolean          $ensure_packages = true,
) {
    include apt

    $exec_name = "exec-apt-get-update-${title}_${distro}-bpo"

    # the bpo archive content drastically changes from release to release
    # so make the distro a mandatory argument and be a NOOP if it mismatches
    if debian::codename::eq($distro) {
        if $ensure_packages {
            ensure_packages($packages)
            $pkg_before = Package[$packages]
        } else {
            $pkg_before = undef
        }
        apt::pin { "apt_pin_${title}_${distro}-bpo":
            pin      => "release a=${distro}-backports",
            package  => join($packages, ' '),
            priority => $priority,
            before   => $pkg_before,
            notify   => Exec[$exec_name],
        }

        exec { $exec_name:
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

    } else {
        notify { "apt::package_from_bpo[${title}] did nothing! requested '${distro}-backports' in '${debian::codename()}'": }
    }
}
