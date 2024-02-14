# == Class: phabricator::logmail
#
# An abstraction to define a shell script that sends
# its output to users via email.
#
# Once used for admin audit log and community metrics
# on Bugzilla, now for similar metrics on Phabricator
# but can be flexible about the script it uses.
#
# === Required Parameters
#
# [*rcpt_address*]
#   mail to: address (or array of addresses)
#
# [*sndr_address*]
#   mail from: address
#
# [*mysql_slave*]
#   mysql (slave) server
#
# [*mysql_slave_port*]
#   port of the mysql (slave) server
#
# [*mysql_db_name*]
#   name of the mysql database accessed by the script
#
# === Optional Parameters
#
# [*basedir*]
#    path to the phabricator tools directory
#
# [*hour*]
#    hour the script is executed
#
# [*minute*]
#    minute the script is executed
#
# [*monthday*]
#    day of the month script is executed
#
# [*month*]
#    month of the year script is executed
#
# [*weekday*]
#    day of the week script is executed, string, Mon-Fri
#
# [*ensure*]
#    Whether to enable the periodic job or not, default present
#
define phabricator::logmail (
    String $sndr_address,
    Variant[String, Array] $rcpt_address,
    Stdlib::Fqdn $mysql_slave,
    String $mysql_slave_port,
    String $mysql_db_name,
    Stdlib::Unixpath $basedir  = '/usr/local/bin',
    Optional[Integer] $hour = 0,
    Optional[Integer] $minute = 0,
    Optional[Variant[String, Integer]] $month = undef,
    Optional[Integer] $monthday = undef,
    Optional[Systemd::Timer::Weekday] $weekday = undef,
    Wmflib::Ensure $ensure = 'present',
) {

    ensure_packages(['mariadb-client'])

    file { "/etc/phab_${title}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => template("phabricator/${title}.conf.erb"),
    }

    file { "${basedir}/${title}.sh":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => file("phabricator/${title}.sh"),
    }

    if $weekday == undef {
        $real_weekday = ''
    } else {
        $real_weekday = "${weekday} "
    }

    if $monthday == undef {
        $real_monthday = '*'
    } else {
        $real_monthday = $monthday
    }

    if $month == undef {
        $real_month = '*'
    } else {
        $real_month = $month
    }

    systemd::timer::job { "phabricator_stats_job_${title}":
        ensure      => $ensure,
        user        => 'root',
        description => "phabricator statistics mail - ${title}",
        command     => "${basedir}/${title}.sh",
        interval    => {'start' => 'OnCalendar', 'interval' => "${real_weekday}*-${real_month}-${real_monthday} ${hour}:${minute}:00"},
    }
}
