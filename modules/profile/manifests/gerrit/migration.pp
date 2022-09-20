# Allow rsyncing gerrit data to another server for
# migration and reinstalls.
class profile::gerrit::migration (
    Stdlib::Fqdn        $src_host    = lookup('profile::gerrit::migration::src_host'),
    Array[Stdlib::Fqdn] $dst_hosts   = lookup('profile::gerrit::migration::dst_hosts'),
    Stdlib::Unixpath    $data_dir    = lookup('profile::gerrit::migration::data_dir'),
    String              $daemon_user = lookup('profile::gerrit::daemon_user'),
) {

    $gerrit_site = "/var/lib/${daemon_user}/review_site"

    if $facts['fqdn'] in $dst_hosts {

        ferm::service { 'gerrit-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(@resolve((${src_host})) @resolve((${src_host}), AAAA))",
        }

        class { 'rsync::server': }

        rsync::server::module { 'gerrit-data':
            path        => $data_dir,
            read_only   => 'no',
            hosts_allow => $src_host,
        }

        rsync::server::module { 'gerrit-var-lib':
            path        => $gerrit_site,
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
