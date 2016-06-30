# == Class: grub
#
# Base class to manage GRUB configuration (mostly boot params right now).
#
# === Parameters
#
# === Examples
#
#  include grub
#

class grub {
    exec { 'update-grub':
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
}
