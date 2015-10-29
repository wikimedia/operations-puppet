class base::grub {
    # The shellvars_list lens is broken with backticks on older versions of
    # Augeas (< jessie), so keep a compatibility version with test/grep/sed
    if versioncmp($::augeasversion, '1.3.0') >= 0 {
        augeas { 'grub2':
            incl    => '/etc/default/grub',
            lens    => 'Shellvars_list.lns',
            changes => [
                # set terminal; default usually is just serial
                'set GRUB_TERMINAL/quote \'"\'',
                'set GRUB_TERMINAL/value[1] console',
                'set GRUB_TERMINAL/value[2] serial',
                # removes quiet, splash from default kopts
                'rm GRUB_CMDLINE_LINUX_DEFAULT/value[. = "quiet"]',
                'rm GRUB_CMDLINE_LINUX_DEFAULT/value[. = "splash"]',
                # The CFQ I/O scheduler is rather suboptimal for some of our I/O
                # workloads. Override with deadline. (the installer does this too)
                'set GRUB_CMDLINE_LINUX/value[. = "elevator=deadline"] elevator=deadline',
            ],
            notify  => Exec['update-grub'],
        }
    } else {
        # Disable the 'quiet' kernel command line option so console messages
        # will be printed.
        exec { 'grub2 remove quiet':
            path    => '/bin:/usr/bin',
            command => "sed -r -i '/^GRUB_CMDLINE_LINUX_DEFAULT/s/quiet( splash)?//' /etc/default/grub",
            onlyif  => "grep -E -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*quiet( splash)?' /etc/default/grub",
            notify  => Exec['update-grub'],
        }

        # show the GRUB menu on both console & serial (default is serial)
        exec { 'grub2 terminal':
            path    => '/bin:/usr/bin',
            command => "sed -i '/^GRUB_TERMINAL/s/=.*/=\"console serial\"/' /etc/default/grub",
            unless  => "grep -q '^GRUB_TERMINAL=.*console serial' /etc/default/grub",
            onlyif  => 'test -f /etc/default/grub',
            notify  => Exec['update-grub'],
        }

        # The CFQ I/O scheduler is rather # suboptimal for some of our I/O
        # workloads. Override with deadline. (the installer does this too)
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
