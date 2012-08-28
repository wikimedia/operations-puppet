# Class: rsync
#
# This module manages rsync
#
class rsync {

  package { 'rsync':
    ensure => installed,
  } -> Rsync::Get<| |>
}
