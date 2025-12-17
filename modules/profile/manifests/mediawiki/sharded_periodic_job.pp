# SPDX-License-Identifier: Apache-2.0
# == define profile::mediawiki::sharded_periodic_job
#
# Helper to parallelize periodic_jobs by shard.
#
# == Parameters
#
# [*script*] The MW script to execute
#
# [*shards*] The shards to run against (e.g. ['s1'])
#
# [*kubernetes_shards*] The shards to run against in kubernetes (e.g. ['s1']), default empty
#
# [*interval*] The frequency with which the job must be executed, expressed as
#              one of the Calendar expressions accepted by systemd. See systemd.time(7)
#
# [*cron_schedule*] The frequency with which the job must be executed, expressed as
#              a cron schedule. See crontab(5). Mandatory for kubernetes.
#
# [*splay*] Sets a maximum delay to wait before starting the timer
#
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
# [*foreachwiki_ignore_errors*] Continue with the next wiki in the loop on error (kubernetes only). Default: false
#
# [*mesh_check_skip*] Script doesn't do calls through the service mesh, don't check it's up (kubernetes only). Default: false
#
# [*ensure*] Either 'present' or 'absent'. Default: present

define profile::mediawiki::sharded_periodic_job(
    String $script,
    Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime
    ] $interval,
    Array[String] $shards = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8'],
    Array[String] $kubernetes_shards = [],
    Optional[Wmflib::Cron_schedule] $cron_schedule = undef,
    Optional[Integer] $splay = undef,
    Boolean $kubernetes = false,
    Optional[String] $script_label = undef,
    Optional[String] $team = undef,
    Optional[String] $description = undef,
    Optional[Stdlib::Unixpath] $helmfile_defaults_dir = '/etc/helmfile-defaults',
    Optional[Integer] $ttlsecondsafterfinished = undef,
    Optional[Integer] $failedjobshistorylimit = undef,
    Optional[Integer] $successfuljobshistorylimit = undef,
    Optional[Boolean] $foreachwiki_ignore_errors = false,
    Optional[Boolean] $mesh_check_skip = false,
    Wmflib::Ensure $ensure = present,
) {
    $real_description = $description ? {
        undef   => $title,
        default => $description,
    }

    $shards.map |$shard| {
        # For back-compat, support "s1@11" style shards
        $real_shard = regsubst($shard, '@.*', '')
        # Inject the dblist as the second argument (after the PHP script)
        $script = regsubst($script, '\.php', ".php ${real_shard}.dblist")

        # If we have not set the whole sharded_periodic_job to run on kubernetes,
        # check if the current shard is part of the kubernetes_shards array.
        unless $kubernetes {
            $kubernetes = $shard in $kubernetes_shards
        }

        profile::mediawiki::periodic_job { "${title}_${shard}":
            ensure                     => $ensure,
            kubernetes                 => $kubernetes,
            command                    => "/usr/local/bin/mwscriptwikiset ${script}",
            interval                   => $interval,
            splay                      => $splay,
            cron_schedule              => $cron_schedule,
            script_label               => $script_label,
            team                       => $team,
            description                => "${real_description} in ${real_shard}",
            helmfile_defaults_dir      => $helmfile_defaults_dir,
            ttlsecondsafterfinished    => $ttlsecondsafterfinished,
            failedjobshistorylimit     => $failedjobshistorylimit,
            successfuljobshistorylimit => $successfuljobshistorylimit,
            foreachwiki_ignore_errors  => $foreachwiki_ignore_errors,
            mesh_check_skip            => $mesh_check_skip,
        }
    }

    profile::mediawiki::periodic_job { "${title}_s11":
        ensure   => absent,
        command  => "/usr/local/bin/mwscriptwikiset ${script}",
        interval => $interval,
    }
}
