# SPDX-License-Identifier: Apache-2.0
define sbuild::chroot(
    String $distribution = $title,
) {
    require ::sbuild

    if debian::codename::ge('buster'){
        $sbuild_cmd    = '/usr/bin/sbuild-createchroot --include=eatmydata,ccache'
    } else {
        $sbuild_cmd    = '/usr/sbin/sbuild-createchroot --include=eatmydata,ccache'
    }
    $sbuild_mirror = 'http://127.0.0.1:3142/deb.debian.org/debian'

    $chroot_name = "${distribution}-amd64-sbuild"
    $chroot_dir  = "/srv/chroot/${chroot_name}"
    $create_cmd  = "${sbuild_cmd} ${distribution} ${chroot_dir} ${sbuild_mirror}"

    # create the chroot
    exec { "sbuild-createchroot-${chroot_name}":
        command => $create_cmd,
        creates => $chroot_dir,
    }

    # schedule daily updates to the chroot
    $update_cmd = "/usr/bin/sbuild-update ${chroot_name}"
    systemd::timer::job { "update-${chroot_name}-chroot":
        ensure      => present,
        description => "update ${chroot_name} chroot for sbuild",
        command     => $update_cmd,
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 08:00:00', #daily at 08:00 UTC, arbitrary
        },
    }
}
