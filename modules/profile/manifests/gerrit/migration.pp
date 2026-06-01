# Allow rsyncing gerrit data to another server for
# migration and reinstalls.
class profile::gerrit::migration (
    Stdlib::Fqdn        $src_host = lookup('profile::gerrit::active_host'),
    Stdlib::Unixpath    $data_dir = lookup('profile::gerrit::migration::data_dir'),
){
    $dst_hosts = wmflib::class::hosts('gerrit').filter |$host| { $host != $src_host }

    rsync::quickdatacopy { 'gerrit-data':
        ensure                     => present,
        auto_sync                  => false,
        source_host                => $src_host,
        dest_host                  => $facts['networking']['fqdn'],
        module_path                => $data_dir,
        chown                      => 'gerrit:gerrit',
        ignore_missing_file_errors => true,
        server_uses_stunnel        => true,
    }

    file { "/srv/home-${src_host}/":
        ensure => directory,
    }

    rsync::quickdatacopy { 'gerrit-home':
        ensure                     => present,
        auto_sync                  => false,
        source_host                => $src_host,
        dest_host                  => $facts['networking']['fqdn'],
        module_path                => "/srv/home-${src_host}",
        chown                      => 'gerrit:gerrit',
        ignore_missing_file_errors => true,
        server_uses_stunnel        => true,
    }
}
