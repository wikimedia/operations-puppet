# == Class: scap::user
#
# Sets up a scap account used by the scap deployment tool to update itself on target hosts via rsync
class scap::user {
  $uid = 919
  $gid = 919
  $home_dir = '/var/lib/scap'

  file { $home_dir:
    ensure => directory,
    owner  => $uid,
    group  => $gid,
    mode   => '0755',
  }

  systemd::sysuser { 'scap':
    id          => "${uid}:${gid}",
    description => 'used to install the scap deployment tool',
    # Changing the home here requires updating the location of the staging dir for scap installs at class scap::master
    home_dir    => $home_dir,
    require     => File[$home_dir]
  }

  ssh::userkey { 'scap':
    content => secret('keyholder/scap.pub'),
  }
}