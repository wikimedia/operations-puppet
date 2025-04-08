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
) {

    if $::_role == 'deployment_server/kubernetes' {
        if $kubernetes {
            profile::mediawiki::periodic_job::kubernetes { $title:
                ensure                  => $ensure,
                command                 => $command,
                cron_schedule           => $cron_schedule,
                splay                   => $splay,
                script_label            => $script_label,
                team                    => $team,
                description             => $description,
                helmfile_defaults_dir   => $helmfile_defaults_dir,
                ttlsecondsafterfinished => $ttlsecondsafterfinished,
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
        profile::mediawiki::periodic_job::systemd{ $title:
            ensure   => $systemd_ensure,
            command  => $command,
            interval => $interval,
            splay    => $splay,
        }
    }
}
