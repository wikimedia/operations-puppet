# SPDX-License-Identifier: Apache-2.0
# @summary provisions the en_US.UTF-8 locale
# this is done by debian-installer on wikiprod hosts, so this profile is mostly
# useful in Cloud VPS
class profile::locales::base () {
  file_line { 'locale-en_US.UTF-8':
    ensure => present,
    path   => '/etc/locale.gen',
    line   => 'en_US.UTF-8 UTF-8',
    notify => Exec['base-locale-gen'],
  }

  exec { 'base-locale-gen':
    command     => '/usr/sbin/locale-gen --purge',
    refreshonly => true,
  }
}
