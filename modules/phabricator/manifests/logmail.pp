# sets up a cronjob and file to mail out
# the results of statistic scripts
#
# once used for admin audit log and community metrics
# on Bugzilla, now for similar metrics on Phabricator
# but can be flexible about the script it uses
#
# required parameters:
#
# script_name - script you want to execute
# sndr_address - mail from: address
# rcpt_address - mail to: address
#
# optional parameters:
#
# phab_tools - path to the phabricator tools directory
# hour - hour the script is executed
# minute - minute the script is executed
# monthday - day of the month script is executed
# (use this to control how often you send mails)
# f.e. * = daily, 1 = monthly, ..)
define phabricator::logmail (
    $script_name,
    $sndr_address,
    $rcpt_address,
    $phab_tools  = '/srv/phab/tools',
    $hour        = '0',
    $minute      = '0',
    $monthday    = '*',
) {

    file { "${phab_tools}/${script_name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => template("phabricator/${script_name}.erb"),
    }

    cron { "phabstatscron_${title}":
        ensure   => present,
        command  => "${phab_tools}/${script_name}",
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        monthday => $monthday,
    }
}

