# SPDX-License-Identifier: Apache-2.0
# a timer (job) to import a list of wikis into a wikistats table
define wikistats::job::import(
    String $weekday,
    String $project = $name,
    Integer $hour = 11,
    Integer $minute = 11,
    Wmflib::Ensure $ensure = 'present',
){

    systemd::timer::job { "wikistats-import-${name}":
        ensure          => $ensure,
        user            => 'root',
        description     => "import a fresh list of wikis into table ${name}",
        command         => "/usr/local/bin/wikistats/import_${project}.sh",
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => "import-${project}.log",
        send_mail       => true,
        environment     => {'MAILTO' => 'dzahn@wikimedia.org'},
        interval        => {'start' => 'OnCalendar', 'interval' => "${weekday} *-*-* ${hour}:${minute}:00"},
    }
}
