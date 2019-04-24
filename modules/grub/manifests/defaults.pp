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
}
