# SPDX-License-Identifier: Apache-2.0
# == Define logster::job
# Installs a logster cronjob.
#
# == Parameters
# $parser            - Logster parser class name to use.
# $logfile           - Path to logfile to tail and report metrics about.
# $logster_options   - Full CLI option string to pass to logster.  Default: undef
#
# This class also takes the usual time frequency parameters that the cron
# resource type does: $minute (defaults to */5), $hour, $weekday, $month, $monthday.
# These are used for scheduling how often you want logster to parse the logfile
# and send metrics.
#
# NOTE: When defining job as 'absent', the package will become unmanaged
# and will need to be removed manually.
#
define logster::job(
    $parser,
    $logfile,
    $ensure          = 'present',
    $logster_options = undef,
    $minute          = '*/5',
    $hour            = undef,
    $weekday         = undef,
    $month           = undef,
    $monthday        = undef,
) {

    if ($ensure == 'present') {
        require ::logster
    }

    cron { "logster-${title}":
        ensure   => $ensure,
        command  => "/usr/bin/logster ${logster_options} ${parser} ${logfile} > /dev/null 2>&1",
        user     => 'root',
        minute   => $minute,
        hour     => $hour,
        weekday  => $weekday,
        month    => $month,
        monthday => $monthday,
    }
}
