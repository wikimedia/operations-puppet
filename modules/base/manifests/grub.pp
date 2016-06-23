class base::grub($ioscheduler = 'deadline', $enable_memory_cgroup = false, $tcpmhash_entries = 0) {
    # The augeas Shellvars_list lens can't handle backticks for
    # versions < 1.2.0 (practically every distro older than jessie).
    # We fallback to the legacy grep/sed method in that case.
    if versioncmp($::augeasversion, '1.2.0') >= 0 and os_version('Debian >= jessie') {
        $cgroup_line = $enable_memory_cgroup ? {
            true => 'set GRUB_CMDLINE_LINUX/value[. = "cgroup_enable=memory"] cgroup_enable=memory',
            false => 'rm GRUB_CMDLINE_LINUX/value[. = "cgroup_enable=memory"]'
        }
        $swapaccount_line = $enable_memory_cgroup ? {
            true => 'set GRUB_CMDLINE_LINUX/value[. = "swapaccount=1"] swapaccount=1',
            false => 'rm GRUB_CMDLINE_LINUX/value[. = "swapaccount=1"]'
        }

        $tcpmhash_line = $tcpmhash_entries ? {
            0       => 'rm GRUB_CMDLINE_LINUX/value[. =~ glob("tcpmhash_entries=*")]',
            default => "set GRUB_CMDLINE_LINUX/value[. =~ glob(\"tcpmhash_entries=*\")] tcpmhash_entries=${tcpmhash_entries}"
        }

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
                # Sets the ioscheduler to a specific value. Default is deadline
                "set GRUB_CMDLINE_LINUX/value[. =~ glob(\"elevator=*\")] elevator=${ioscheduler}",
                $cgroup_line,
                $swapaccount_line,
                $tcpmhash_line,
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

        # The CFQ I/O scheduler is rather suboptimal for some of our I/O
        # workloads. Override with deadline. (the installer does this too)
        exec { 'grub2 iosched deadline':
            path    => '/bin:/usr/bin',
            command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=${ioscheduler}\\\"/' /etc/default/grub",
            unless  => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=${ioscheduler}' /etc/default/grub",
            onlyif  => 'test -f /etc/default/grub',
            notify  => Exec['update-grub'];
        }
    }

    exec { 'update-grub':
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
}
