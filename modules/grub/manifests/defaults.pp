# == Class: grub::defaults
#
# Default GRUB/Linux options. Unparameterized and thus mostly settings that are
# globally sensible, not able to be set with grub::bootparam and not worth it
# to abstract into another define.
#
# === Parameters
#
# === Examples
#
#  include grub::defaults
#

class grub::defaults {
    include ::grub

    # The augeas Shellvars_list lens can't handle backticks for versions < 1.2
    # We fallback to the legacy grep/sed method in that case.
    if versioncmp($::augeasversion, '1.2.0') >= 0 {
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
    }
}
