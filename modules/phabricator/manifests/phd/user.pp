# SPDX-License-Identifier: Apache-2.0
class phabricator::phd::user(
  String $user_name = 'phd',
  Stdlib::Unixpath $home_dir = "/var/run/${user_name}",
  Integer $uid = 920, # reserved in modules/admin/data/data.yaml
  Integer $gid = $uid, # in our setup normally GID always equals UID
) {

    file { $home_dir:
        ensure => directory,
        owner  => $user_name,
        group  => $user_name,
    }

    systemd::sysuser { $user_name:
        ensure      => present,
        id          => "${uid}:${gid}",
        description => 'Phabricator daemon user',
        home_dir    => $home_dir,
        require     => File[$home_dir],
    }
}
