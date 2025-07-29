class profile::mediawiki::maintenance::parsercachepurging(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'data-persistence'

    # Every day, Purge entries older than 30d * 86400s/d = 2592000s
    #
    # WARNING: Increasing msleep may cause exponential growth. Deletes must outpace other writes! (T282761)
    #
    ['pc1', 'pc2', 'pc3', 'pc4', 'pc5', 'pc6', 'pc7', 'pc8'].each |$pc_cluster| {
        profile::mediawiki::periodic_job { "purge_parsercache_${pc_cluster}":
            ensure                => absent,
            command               => "/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag ${pc_cluster} --age=2592000 --msleep 200",
            interval              => '01:00',
            cron_schedule         => '0 1 * * *',
            kubernetes            => true,
            team                  => $team,
            script_label          => 'purgeParserCache.php',
            description           => "Purge parsercache entries for ${pc_cluster} once a day at 01:00.",
            helmfile_defaults_dir => $helmfile_defaults_dir,
        }
    }
}
