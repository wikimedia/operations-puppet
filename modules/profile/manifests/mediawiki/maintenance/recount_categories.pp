class profile::mediawiki::maintenance::recount_categories(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'recount_categories':
        command  => '/usr/local/bin/foreachwiki recountCategories.php --mode all',
        interval => '*-*-01 04:00'

    }
}
