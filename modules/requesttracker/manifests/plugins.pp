# installs plugins for a Wikimedia RT install
# currently: Shredder (to safely delete things)
# add more plugins here if desired
class requesttracker::plugins {

  # RT Shredder plugin
  file { '/var/cache/request-tracker4/data/RT-Shredder':
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0750',
  }

}

