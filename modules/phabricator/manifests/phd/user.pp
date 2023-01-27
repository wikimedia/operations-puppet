# SPDX-License-Identifier: Apache-2.0
class phabricator::phd::user(
  String $user_name = 'phd',
  Stdlib::Unixpath $home_dir = "/var/run/${user_name}",
) {

    # global UID reserved in modules/admin/data/data.yaml
    $uid = assert_type(Admin::UID::System::Global, 920)
    # in our setup normally GID always equals UID
    $gid = assert_type(Admin::UID::System::Global, $uid)

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
    }
}
