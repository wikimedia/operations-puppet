# == Class: phabricator::logmail
#
# once used for admin audit log and community metrics
# on Bugzilla, now for similar metrics on Phabricator
# but can be flexible about the script it uses
#
# === Required Parameters
#
# [*scriptname*]
#   script you want to execute
#
# [*rcpt_address*]
#   mail to: address (or array of addresses)
#
# [*sndr_address*]
#   mail from: address
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
# [*weekday*]
#    day of the week script is executed
#
# [*ensure*]
#    Whether to enable the cron or not, default present

define phabricator::logmail (
    $script_name,
    $sndr_address,
    $rcpt_address,
    $basedir  = '/usr/local/bin',
    $hour        = '0',
    $minute      = '0',
    $monthday    = undef,
    $weekday     = undef,
    $ensure      = present,
) {


    file { "${basedir}/${script_name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => template("phabricator/${script_name}.erb"),
    }

    cron { "phabstatscron_${title}":
        ensure   => $ensure,
        command  => "${basedir}/${script_name}",
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        weekday  => $weekday,
        monthday => $monthday,
    }
}
