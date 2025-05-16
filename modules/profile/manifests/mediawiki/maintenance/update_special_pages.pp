class profile::mediawiki::maintenance::update_special_pages(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::sharded_periodic_job { 'update_special_pages':
        script                  => 'updateSpecialPages.php',
        interval                => '*-1/3 05:00',
        cron_schedule           => '00 05 */3 * *',
        kubernetes              => true,
        team                    => 'mediawiki-special-pages',
        script_label            => 'updateSpecialPages.php',
        description             => 'Update cached special pages',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 345600, # 4 days
    }
}
