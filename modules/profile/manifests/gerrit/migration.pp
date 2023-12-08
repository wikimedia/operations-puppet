# Allow rsyncing gerrit data to another server for
# migration and reinstalls.
class profile::gerrit::migration (
    Stdlib::Fqdn        $src_host    = lookup('profile::gerrit::migration::src_host'),
    Array[Stdlib::Fqdn] $dst_hosts   = lookup('profile::gerrit::migration::dst_hosts'),
    Stdlib::UnixPath    $gerrit_site = lookup('profile::gerrit::gerrit_site'),
    Stdlib::Unixpath    $data_dir    = lookup('profile::gerrit::migration::data_dir'),
    String              $daemon_user = lookup('profile::gerrit::migration::daemon_user'),
) {

    if $facts['fqdn'] in $dst_hosts {

        firewall::service { 'gerrit-migration-rsync':
            proto  => 'tcp',
            port   => 873,
            srange => [$src_host],
        }

        class { 'rsync::server': }

        rsync::server::module { 'gerrit-data':
            path        => $data_dir,
            read_only   => 'no',
            hosts_allow => [$src_host],
        }

        rsync::server::module { 'gerrit-var-lib':
            path        => $gerrit_site,
            read_only   => 'no',
            hosts_allow => [$src_host],
        }

        file { "/srv/home-${src_host}/":
            ensure => directory,
        }

        if !defined(File[$gerrit_site]) {
            file { $gerrit_site:
                ensure => directory,
            }
        }

        rsync::server::module { 'gerrit-home':
            path        => "/srv/home-${src_host}",
            read_only   => 'no',
            hosts_allow => [$src_host],
        }
    }
}
