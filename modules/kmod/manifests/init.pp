#
# == Class: kmod
#
# Ensures a couple of mandatory files are present before managing their
# content.
#
#
class kmod {

  if versioncmp($::augeasversion, '0.9.0') < 0 {
    fail('Augeas 0.10.0 or higher required')
  }
  file { '/etc/modprobe.d': ensure => directory }

  file { [
      '/etc/modprobe.d/modprobe.conf',
      '/etc/modprobe.d/aliases.conf',
      '/etc/modprobe.d/blacklist.conf',
    ]: ensure => file,
  }
}
