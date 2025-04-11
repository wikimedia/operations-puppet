class profile::mediawiki::maintenance::initsitestats(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'initsitestats':
        command  => '/usr/local/bin/foreachwiki initSiteStats.php --update',
        interval => '*-*-* 21:00:00',
    }
}
