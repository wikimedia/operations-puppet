# Allow rsyncing gerrit data to another server for
# migration and reinstalls.
class profile::gerrit::migration (
    Stdlib::Fqdn        $src_host    = lookup('profile::gerrit::active_host'),
    Stdlib::UnixPath    $gerrit_site = lookup('profile::gerrit::gerrit_site'),
    Stdlib::Unixpath    $data_dir    = lookup('profile::gerrit::migration::data_dir'),
    String              $daemon_user = lookup('profile::gerrit::migration::daemon_user'),
) {
    $dst_hosts = wmflib::class::hosts('gerrit').filter |$host| { $host != $src_host }

    if $facts['fqdn'] in $dst_hosts {

        class { 'rsync::server': }

        rsync::server::module { 'gerrit-data':
            path          => $data_dir,
            read_only     => 'no',
            auto_firewall => true,
            hosts_allow   => [$src_host],
        }

        rsync::server::module { 'gerrit-var-lib':
            path          => $gerrit_site,
            read_only     => 'no',
            auto_firewall => true,
            hosts_allow   => [$src_host],
        }

        file { "/srv/home-${src_host}/":
            ensure => directory,
        }

        if !defined(File[$gerrit_site]) {
            ensure_resource('file', $gerrit_site, {'ensure' => 'directory'})
        }

        rsync::server::module { 'gerrit-home':
            path          => "/srv/home-${src_host}",
            read_only     => 'no',
            auto_firewall => true,
            hosts_allow   => [$src_host],
        }
    }
}
