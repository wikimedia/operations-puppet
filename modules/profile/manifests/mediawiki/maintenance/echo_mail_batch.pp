class profile::mediawiki::maintenance::echo_mail_batch(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'echo_mail_batch':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/echo.dblist extensions/Echo/maintenance/processEchoEmailBatch.php',
        interval => '00:00',
    }
}

