class profile::mediawiki::maintenance::purge_checkuser(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'purge_checkuser':
        command  => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php',
        interval => '00:00'
    }
}
