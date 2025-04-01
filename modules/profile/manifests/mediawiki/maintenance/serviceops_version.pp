# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::serviceops_version(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'serviceops_version':
        command               => '/usr/local/bin/expanddblist large | xargs -I{} -P4 /usr/local/bin/mwscript Version.php --wiki={}',
        cron_schedule         => '*/10 * * * *',
        team                  => 'sre-serviceops',
        script_label          => 'Version.php',
        description           => 'Run version.php on all wikis in large.dblist every 10 minutes with 4 parallel processes',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
