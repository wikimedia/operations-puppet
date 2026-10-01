# SPDX-License-Identifier: Apache-2.0
# a timer (job) to update a wikistats table
define wikistats::job::update (
    String $project = $name,
    Integer $hour = 0,
    Integer $minute = 0,
    Optional[String] $day = undef,
    Wmflib::Ensure $ensure = 'present',
){

    $minute_extinfo = $minute + 30

    if $day {
        $interval = "${day} *-*-* ${hour}:${minute}:00"
        $interval_extinfo = "${day} *-*-* ${hour}:${minute_extinfo}:00"
    } else {
        $interval = "*-*-* ${hour}:${minute}:00"
        $interval_extinfo = "*-*-* ${hour}:${minute_extinfo}:00"
    }

    systemd::timer::job { "wikistats-update-${name}":
        ensure          => $ensure,
        user            => 'wikistatsuser',
        description     => "pull fresh numbers for table ${name}",
        command         => "/usr/bin/php /usr/lib/wikistats/update.php ${project}",
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => "update-${name}.log",
        interval        => {'start' => 'OnCalendar', 'interval' => $interval},
    }

    systemd::timer::job { "wikistats-extinfo-update-${name}":
        ensure          => $ensure,
        user            => 'wikistatsuser',
        description     => "pull extended info for table ${name}",
        command         => "/usr/bin/php /usr/lib/wikistats/update.php ${project} extinfo",
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => "update-extinfo-${name}.log",
        interval        => {'start' => 'OnCalendar', 'interval' => $interval_extinfo},
    }
}
