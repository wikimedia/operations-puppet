# SPDX-License-Identifier: Apache-2.0
# == define profile::mediawiki::periodic_job::kubernetes
#
# Helper for defining multi-dc-safe MediaWiki jobs as kubernetes cronjobs.
# This allows to run the timers in both dcs, but only execute the commands in
# the active dc (per conftool).
#
# See also deployment-charts/helmfile.d/services/mw-cron
#
# == Parameters
#
# [*command*] The command to execute
#
# [*cron_schedule*] The frequency with which the job must be executed, expressed as
#                   a cron schedule expression.
#
# [*splay*] Sets a maximum delay to wait before starting the timer (not implemented yet)
#
# [*ensure*] Either 'present' or 'absent'. Default: present
#
# [*helmfile_defaults_dir*] The helmfile defaults directory to store the periodic jobs in. Default: /etc/helmfile-defaults
#
# [*script_label*] Kubernetes cronjob label showing which script is running. Just a label. Default: undef
#
# [*team*] The team responsible for the job. Default: undef
#
# [*description*] The description of the job. Default: undef

define profile::mediawiki::periodic_job::kubernetes(
    String $command,
    Wmflib::Cron_schedule $cron_schedule = undef,
    Wmflib::Ensure $ensure = present,
    Optional[Integer] $splay = undef,
    String $script_label = undef,
    String $team = undef,
    String $description = undef,
    Stdlib::Unixpath $helmfile_defaults_dir = '/etc/helmfile-defaults',
) {
    if $ensure == 'present' {
        $command_quoted = $command.to_json()
        concat_fragment { "mediawiki_job_${title}":
            content => template('profile/mediawiki/maintenance/kubernetes_periodic_job.tmpl.erb'),
            target  => "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml",
        }
    }
}
