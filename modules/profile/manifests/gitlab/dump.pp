# SPDX-License-Identifier: Apache-2.0
# A place to temp. dump gitlab backups until T274463 is resolved
class profile::gitlab::dump(
    Stdlib::Unixpath $backup_path = lookup('profile::gitlab::dump::backup_path',
                { 'default_value' => '/srv/gitlab-backup'}),
){

    wmflib::dir::mkdir_p($backup_path)

    ensure_packages(['rsync'])

    rsync::server::module { 'gitlab-dump':
        ensure         => present,
        read_only      => 'no',
        path           => $backup_path,
        hosts_allow    => ['gitlab1001.wikimedia.org', 'gitlab1004.wikimedia.org'],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }
}
