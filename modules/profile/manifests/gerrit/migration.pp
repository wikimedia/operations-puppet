# Allow rsyncing gerrit data to another server for
# migration and reinstalls.
class profile::gerrit::migration (
    Stdlib::Fqdn        $src_host = lookup('profile::gerrit::active_host'),
    Stdlib::Unixpath    $data_dir = lookup('profile::gerrit::migration::data_dir'),
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

        file { "/srv/home-${src_host}/":
            ensure => directory,
        }

        rsync::server::module { 'gerrit-home':
            path          => "/srv/home-${src_host}",
            read_only     => 'no',
            auto_firewall => true,
            hosts_allow   => [$src_host],
        }
    }
}
