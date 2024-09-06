# SPDX-License-Identifier: Apache-2.0
# allow rsyncing data between CI servers during server migrations
class profile::ci::data_rsync (
    Stdlib::Fqdn $src_host = lookup(profile::ci::migration::rsync_src_host),
    Array[Stdlib::Fqdn] $dst_hosts = lookup(profile::ci::migration::rsync_dst_hosts),
    Array[Stdlib::Unixpath] $data_dirs = lookup(profile::ci::migration::rsync_data_dirs),
) {

    if $::fqdn in $dst_hosts {

        firewall::service { 'ci-migration-rsync':
            proto  => 'tcp',
            port   => 873,
            srange => [$src_host],
        }

        class { '::rsync::server': }

        $data_dirs.each |String $data_dir| {

            $module_name = regsubst($data_dir, '\/', '-', 'G')

            rsync::server::module { "ci-${module_name}":
                path        => $data_dir,
                read_only   => 'no',
                hosts_allow => [$src_host],
            }
        }
    }
}
