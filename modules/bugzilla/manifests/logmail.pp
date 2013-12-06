# define that sets up a cronjob and file to mail out
# the results of bugzilla statistic scripts
#
# currently used for admin audit log and community metrics
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
# bz_path - path to the bugzilla installation
# script_user - user running the script
# hour - hour the script is executed
# minute - minute the script is executed
# monthday - day of the month script is executed
# (use this to control how often you send mails)
# f.e. * = daily, 1 = monthly, ..)
define bugzilla::logmail (
    $script_name,
    $sndr_address,
    $rcpt_address,
    $bz_path     = '/srv/org/wikimedia/bugzilla',
    $script_user = 'www-data',
    $hour        = '0',
    $minute      = '0',
    $monthday    = '*',
) {

    file { "${bz_path}/${script_name}":
        ensure   => present,
        owner    => 'root',
        group    => $script_user,
        mode     => '0550',
        content  => template("bugzilla/scripts/${script_name}.erb"),
    }

    cron { "bugzillacron_${title}":
        command  => "${bz_path}/${script_name}",
        user     => $script_user,
        hour     => $hour,
        minute   => $minute,
        monthday => $monthday,
    }
}

