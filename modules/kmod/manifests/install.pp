#
# == Definition: kmod::install
#
# Set a kernel module as installed.
#
# Parameters:
# - *ensure*: present/absent;
# - *command*: optionally, set the command associated with the kernel module;
# - *file*: optionally, set the file where the stanza is written.
#
# Example usage:
#
#   kmod::install { 'pcspkr': }
#
define kmod::install(
  $ensure=present,
  $command='/bin/true',
  $file="/etc/modprobe.d/${name}.conf",
) {

  kmod::setting { "kmod::install ${title}":
    ensure   => $ensure,
    module   => $name,
    file     => $file,
    category => 'install',
    option   => 'command',
    value    => $command,
  }

}
