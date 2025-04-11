class profile::mediawiki::maintenance::readinglists(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'readinglists_purge':
        command  => '/usr/local/bin/mwscript extensions/ReadingLists/maintenance/purge.php --wiki=metawiki',
        interval => '02:42',
    }
}
