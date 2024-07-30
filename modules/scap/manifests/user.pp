# SPDX-License-Identifier: Apache-2.0
# == Class: scap::user
#
# Sets up a scap account used by the scap deployment tool to update itself on target hosts via rsync
class scap::user {
  $uid = assert_type(Admin::UID::System::Global, 919)
  $gid = assert_type(Admin::UID::System::Global, $uid)
  $home_dir = assert_type(Stdlib::Unixpath, '/var/lib/scap')

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
    # and the symlink created at class scap (init.pp file)
    home_dir    => $home_dir,
    require     => File[$home_dir],
    shell       => '/bin/bash',
  }

  ssh::userkey { 'scap':
    content => secret('keyholder/scap.pub'),
  }
}
