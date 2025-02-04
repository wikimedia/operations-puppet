# == define profile::mediawiki::periodic_job
#
# Helper for defining multi-dc-safe MediaWiki jobs as systemd timers or kubernetes cron jobs.
#
# This allows to run the timers in both dcs, but only execute the commands in
# the active dc (per conftool).
#
# For kubernetes cronjobs, see deployment-charts/helmfile.d/services/mw-cron
#
# == Parameters
#
# [*command*] The command to execute
#
# [*interval*] The frequency with which the job must be executed, expressed as
#              one of the Calendar expressions accepted by systemd. See systemd.time(7)
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

define profile::mediawiki::periodic_job(
    String $command,
    Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime,
        Wmflib::Cron_schedule
    ] $interval,
    Wmflib::Ensure $ensure = present,
    Optional[Integer] $splay = undef,
    Boolean $kubernetes = false,
    Optional[String] $script_label = undef,
    Optional[String] $team = undef,
    Optional[String] $description = undef,
    Optional[Stdlib::Unixpath] $helmfile_defaults_dir = '/etc/helmfile-defaults',
) {

    if $::_role == 'deployment_server/kubernetes' and $kubernetes {
        if $ensure == 'present' {
            concat_fragment { "mediawiki_job_${title}":
                    content => template('profile/mediawiki/maintenance/kubernetes_periodic_job.tmpl.erb'),
                    target  => "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml",
                }
        }
    } else {
        require ::profile::mediawiki::common
        require ::profile::conftool::state
        $systemd_ensure = $kubernetes ? {
            true    => 'absent',
            default => $ensure,
        }
        systemd::timer::job { "mediawiki_job_${title}":
            ensure            => $systemd_ensure,
            description       => "MediaWiki periodic job ${title}",
            command           => "/usr/local/bin/mw-cli-wrapper ${command}",
            interval          => {'start' => 'OnCalendar', 'interval' => $interval},
            user              => $::mediawiki::users::web,
            logfile_basedir   => '/var/log/mediawiki',
            logfile_group     => $::mediawiki::users::web,
            syslog_identifier => "mediawiki_job_${title}",
            splay             => $splay,
            require           => File['/usr/local/bin/mw-cli-wrapper']
        }
    }
}
