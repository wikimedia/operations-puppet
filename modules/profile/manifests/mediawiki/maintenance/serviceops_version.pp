# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::serviceops_version(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'serviceops_version':
        command               => '/usr/local/bin/foreachwikiindblist testwikis.dblist Version.php',
        interval              => '*/10 * * * *',
        team                  => 'sre-serviceops',
        script_label          => 'Version.php',
        description           => 'Run version.php on all wikis in testwikis.dblist every 10 minutes to test cronjobs',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
