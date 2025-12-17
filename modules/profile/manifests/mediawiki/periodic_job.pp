# SPDX-License-Identifier: Apache-2.0
# == define profile::mediawiki::periodic_job
#
# Helper for defining multi-dc-safe MediaWiki jobs as systemd timers or kubernetes cron jobs.
#
# This allows to run the timers in both dcs, but only execute the commands in
# the active dc (per conftool).
#
# For kubernetes cronjobs, see deployment-charts/helmfile.d/services/mw-cron
#
# For jobs that run only on kubernetes, see profile::mediawiki::periodic_job::kubernetes
# For jobs that run only on systemd, see profile::mediawiki::periodic_job::systemd
# Hybrid jobs that run on both kubernetes and systemd (all jobs that need to run on beta) will need
# to define both cron_schedule and interval.
#
# == Parameters
#
# [*command*] The command to execute
#
# [*interval*] The frequency with which the job must be executed, expressed as
#          one of the Calendar expressions accepted by systemd. See systemd.time(7). Mandatory for systemd.
#
# [*cron_schedule*] The frequency with which the job must be executed, expressed as
#              a cron schedule. See crontab(5). Mandatory for kubernetes.
#
# [*splay*] Sets a maximum delay to wait before starting the timer
#
# [*ensure*] Either 'present' or 'absent'. Default: present
#
# [*kubernetes*] Boolean, defines the job as a mw-cron job instead of a systemd.timer Default: false
#
# [*helmfile_defaults_dir*] The helmfile defaults directory to store the periodic jobs in. Default: /etc/helmfile-defaults
#
# [*script_label*] Kubernetes cronjob label showing which script is running. Just a label. Default: undef
#
# [*team*] The team responsible for the job. Default: undef
#
# [*description*] The description of the job. Default: undef
#
# [*ttlsecondsafterfinished*] How long the created job objects stay in kubernetes (chart default 1.2d). Default: undef
#
# [*failedjobshistorylimit*] How many failed jobs to keep in history (chart default 1). Default: undef
#
# [*successfuljobshistorylimit*] How many successful jobs to keep in history (chart default 3). Default: undef
#
# [*migration_title*] a string used to reference the old periodic job for removal when migrating to Kubernetes in a situation where the job needs to be renamed.
#
# [*concurrency_policy*] A kubernetes policy for what happens to jobs that run concurrently/overlap. Default is undef, which implies "Replace" in the chart
#
# [*startingdeadlineseconds*] Defines a deadline in whole seconds for starting the Job if the exact timer is missed. Default: undef
#
# [*foreachwiki_ignore_errors*] Continue with the next wiki in the loop on error (kubernetes only). Default: false
#
# [*mesh_check_skip*] Script doesn't do calls through the service mesh, don't check it's up (kubernetes only). Default: false


define profile::mediawiki::periodic_job(
    String $command,
    Optional[Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime,
    ]] $interval = undef,
    Optional[Wmflib::Cron_schedule] $cron_schedule = undef,
    Wmflib::Ensure $ensure = present,
    Optional[Integer] $splay = undef,
    Boolean $kubernetes = false,
    Optional[String] $script_label = undef,
    Optional[String] $team = undef,
    Optional[String] $description = undef,
    Optional[Stdlib::Unixpath] $helmfile_defaults_dir = '/etc/helmfile-defaults',
    Optional[Integer] $ttlsecondsafterfinished = undef,
    Optional[Integer] $failedjobshistorylimit = undef,
    Optional[Integer] $successfuljobshistorylimit = undef,
    Optional[String] $migration_title = undef,
    Optional[Enum['Allow','Forbid','Replace']] $concurrency_policy = undef,
    Optional[Integer] $startingdeadlineseconds = undef,
    Optional[Boolean] $foreachwiki_ignore_errors = false,
    Optional[Boolean] $mesh_check_skip = false,
) {

    if $::_role == 'deployment_server/kubernetes' {
        if $kubernetes {
            $few_ignore_errors_env = $foreachwiki_ignore_errors ? {
                true  => 'FOREACHWIKI_IGNORE_ERRORS=1 ',
                false => '',
            }
            $mcs_env = $mesh_check_skip ? {
                true  => 'MESH_CHECK_SKIP=1 ',
                false => '',
            }
            $real_command = "${few_ignore_errors_env}${mcs_env}${command}"

            profile::mediawiki::periodic_job::kubernetes { $title:
                ensure                     => $ensure,
                command                    => $real_command,
                cron_schedule              => $cron_schedule,
                splay                      => $splay,
                script_label               => $script_label,
                team                       => $team,
                description                => $description,
                helmfile_defaults_dir      => $helmfile_defaults_dir,
                ttlsecondsafterfinished    => $ttlsecondsafterfinished,
                failedjobshistorylimit     => $failedjobshistorylimit,
                successfuljobshistorylimit => $successfuljobshistorylimit,
                concurrency_policy         => $concurrency_policy,
                startingdeadlineseconds    => $startingdeadlineseconds,
            }
        }
    } else {
        require ::profile::mediawiki::common
        require ::profile::conftool::state
        # Remove the timer from systemd on production if it's defined as a kubernetes cronjob,
        # but keep it on labs.
        if $::realm == 'production' {
            $systemd_ensure = $kubernetes ? {
                true    => 'absent',
                default => $ensure,
            }
        } else {
            $systemd_ensure = $ensure
        }
        $timer_title = $migration_title ? {
            undef   => $title,
            default => $migration_title
        }

        profile::mediawiki::periodic_job::systemd{ $timer_title:
            ensure   => $systemd_ensure,
            command  => $command,
            interval => $interval,
            splay    => $splay,
        }
    }
}
