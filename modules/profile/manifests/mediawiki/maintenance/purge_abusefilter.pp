class profile::mediawiki::maintenance::purge_abusefilter(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'purge_abusefilteripdata':
        command  => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/PurgeOldLogIPData.php',
        interval => '01:15'
    }
}
