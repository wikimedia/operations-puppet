# cron and script to mail out different bz stats
# like admin audit log and community metrics

define bugzilla::logmail (
    $bz_path     = '/srv/org/wikimedia/bugzilla',
    $script_name,
    $script_user = 'www-data',
    $rcpt_address,
    $sndr_address,
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

