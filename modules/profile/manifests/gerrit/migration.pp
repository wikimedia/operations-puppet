# Allow rsyncing gerrit data to another server for
# migrations and reinstalls.
class profile::gerrit::migration (
    $src_host = lookup(gerrit::server::rsync_src_host),
    $dst_host = lookup(gerrit::server::rsync_dst_host),
    $data_dir = lookup(gerrit::server::rsync_data_dir),
) {

    if $::fqdn == $dst_host {

        ferm::service { 'gerrit-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(@resolve((${src_host})) @resolve((${src_host}), AAAA))",
        }

        class { '::rsync::server': }

        rsync::server::module { 'gerrit-data':
            path        => $data_dir,
            read_only   => 'no',
            hosts_allow => $src_host,
        }

        rsync::server::module { 'gerrit-var-lib':
            path        => '/var/lib/gerrit2/review_site',
            read_only   => 'no',
            hosts_allow => $src_host,
        }

        file { "/srv/home-${src_host}/":
            ensure => 'directory',
        }

        rsync::server::module { 'gerrit-home':
            path        => "/srv/home-${src_host}",
            read_only   => 'no',
            hosts_allow => $src_host,
        }
    }
}
