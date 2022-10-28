# SPDX-License-Identifier: Apache-2.0
# Class to be added to the installserver
# role to allow copying files for a migration
# to a new server.
# Define source host, destination host and
# data directory in Hiera to get rsyncd and ferm rules
# on the destination host.
# Then manually push from the source to one or multiple
# destinations.
class profile::installserver::migration (
    Stdlib::Fqdn $src_host = lookup(profile::installserver::migration::rsync_src_host),
    Array[Stdlib::Fqdn] $dst_hosts = lookup(profile::installserver::migration::rsync_dst_hosts),
    String $data_dir = lookup(profile::installserver::migration::rsync_data_dir),
) {

    file { "/srv/${data_dir}-${src_host}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $::fqdn in $dst_hosts {

        ferm::service { 'installserver-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(@resolve((${src_host})) @resolve((${src_host}), AAAA))",
        }

        class { '::rsync::server': }

        rsync::server::module { "installserver-${data_dir}":
            path        => "/srv/${data_dir}-${src_host}/",
            read_only   => 'no',
            hosts_allow => $src_host,
        }

    }
}
