# Include this to add periodic jobs calling refreshLinks.php on all clusters. (T80599)
class profile::mediawiki::maintenance::refreshlinks(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # These jobs run monthly, staggered by day of the month.
    $shard_to_day = {'s1' => 1, 's2' => 2, 's3' => 3, 's4' => 4, 's5' => 5, 's6' => 6, 's7' => 7, 's8' => 8}
    # TODO: T388530 - Remove kubernetes_shards when all shards are migrated.
    $kubernetes_shards = ['s6']
    $shard_to_day.map |$shard, $day_of_month| {
        profile::mediawiki::periodic_job { "refreshlinks-delete-from-nonexistent-${shard}":
            command               => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${shard}.dblist --dfn-only",
            interval              => "*-${day_of_month} 00:00",
            kubernetes            => $shard in $kubernetes_shards,
            cron_schedule         => "00 00 ${day_of_month} * *",
            team                  => 'mediawiki-page-derived-data',
            description           => "Refresh link tables in ${shard}, deleting links from nonexistent articles only",
            script_label          => 'refreshLinks.php--dfn-only',
            helmfile_defaults_dir => $helmfile_defaults_dir,
            migration_title       => "cron-refreshlinks-${shard}@${day_of_month}",
        }
    }
}
