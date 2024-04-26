# SPDX-License-Identifier: Apache-2.0
# setup rsync for misc. apps data 
class profile::miscweb::rsync (
    Stdlib::Fqdn        $src_host  = lookup('profile::miscweb::rsync::src_host'),
    Array[Stdlib::Fqdn] $dst_hosts = lookup('profile::miscweb::rsync::dst_hosts'),
){

    if $::fqdn in $dst_hosts {

        firewall::service { 'miscapps-rsync':
            proto  => 'tcp',
            port   => 873,
            srange => [$src_host],
        }

        class { '::rsync::server': }

        rsync::server::module { 'miscapps-srv':
            path        => '/srv/',
            read_only   => 'no',
            hosts_allow => [$src_host],
        }

        profile::auto_restarts::service { 'rsync': }
    }
}
