#
# == Definition: kmod::blacklist
#
# Set a kernel module as blacklisted.
#
# Parameters:
# - *ensure*: present/absent;
# - *file*: optionally, set the file where the stanza is written.
#
# Example usage:
#
#   kmod::blacklist { 'pcspkr': }
#
define kmod::blacklist(
  $ensure=present,
  $file='/etc/modprobe.d/blacklist.conf',
) {


  kmod::setting { "kmod::blacklist ${title}":
    ensure   => $ensure,
    module   => $name,
    file     => $file,
    category => 'blacklist',
  }

}
