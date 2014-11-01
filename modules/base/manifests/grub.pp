class base::grub {
    # Disable the 'quiet' kernel command line option so console messages
    # will be printed.
    exec { 'grub1 remove quiet':
        path    => '/bin:/usr/bin',
        command => "sed -i '/^# defoptions.*[= ]quiet /s/quiet //' /boot/grub/menu.lst",
        onlyif  => "grep -q '^# defoptions.*[= ]quiet ' /boot/grub/menu.lst",
        notify  => Exec['update-grub'],
    }

    exec { 'grub2 remove quiet':
        path    => '/bin:/usr/bin',
        command => "sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/s/quiet splash//' /etc/default/grub",
        onlyif  => "grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' /etc/default/grub",
        notify  => Exec['update-grub'],
    }

    # Ubuntu Precise Pangolin no longer has a server kernel flavour.
    # The generic flavour uses the CFQ I/O scheduler, which is rather
    # suboptimal for some of our I/O work loads. Override with deadline.
    # (the installer does this too, but not for Lucid->Precise upgrades)
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        exec { 'grub1 iosched deadline':
            path    => '/bin:/usr/bin',
            command => "sed -i '/^# kopt=/s/\$/ elevator=deadline/' /boot/grub/menu.lst",
            unless  => "grep -q '^# kopt=.*elevator=deadline' /boot/grub/menu.lst",
            onlyif  => 'test -f /boot/grub/menu.lst',
            notify  => Exec['update-grub'],
        }

        exec { 'grub2 iosched deadline':
            path    => '/bin:/usr/bin',
            command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=deadline\\\"/' /etc/default/grub",
            unless  => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=deadline' /etc/default/grub",
            onlyif  => 'test -f /etc/default/grub',
            notify  => Exec['update-grub'];
        }
    }

    exec { 'update-grub':
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
}