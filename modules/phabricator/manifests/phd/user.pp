# SPDX-License-Identifier: Apache-2.0
class phabricator::phd::user(
  String $user_name = 'phd',
) {

    # global UID reserved in modules/admin/data/data.yaml
    $uid = assert_type(Admin::UID::System::Global, 920)
    # in our setup normally GID always equals UID
    $gid = assert_type(Admin::UID::System::Global, $uid)

    systemd::sysuser { $user_name:
        ensure      => present,
        id          => "${uid}:${gid}",
        description => 'Phabricator daemon user',
        # Created by systemd when starting the service
        home_dir    => '/var/run/phd',
    }
}
