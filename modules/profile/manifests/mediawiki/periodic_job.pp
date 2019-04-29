# == define profile::mediawiki::periodic_job
#
# Helper for defining multi-dc-safe MediaWiki jobs as systemd timers.
#
# This allows to run the timers in both dcs, but only execute the commands in
# the active dc. (per conftool)
#
# == Parameters
#
# [*command*] The command to execute
#
# [*interval*] The frequency with which the job must be executed, expressed as
#              one of the Calendar expressions accepted by systemd. See systemd.time(7)
#
define profile::mediawiki::periodic_job(
    String $command,
    Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime
    ] $interval
) {
    require ::profile::mediawiki::common
    require ::profile::conftool::state

    systemd::timer::job { "mediawiki_job_${title}":
        description       => "MediaWiki periodic job ${title}",
        command           => "/usr/local/bin/mw-cli-wrapper ${command}",
        interval          => {'start' => 'OnCalendar', 'interval' => $interval},
        user              => $::mediawiki::users::web,
        logfile_basedir   => '/var/log/mediawiki',
        logfile_group     => $::mediawiki::users::web,
        syslog_identifier => "mediawiki_job_${title}",
        require           => File['/usr/local/bin/mw-cli-wrapper']
    }
}
