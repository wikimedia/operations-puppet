# setup script and cron to send metrics per
# RT-3962 - mail bz user stats to community metrics

class bugzilla::communitymetrics ($bz_path, $script_user, $script_name, $rcpt_address, $sndr_address) {

    file { 'bugzilla_communitymetrics_file':
        ensure  => present,
        path    => "${bz_path}/${script_name}",
        owner   => 'root',
        group   => $script_user,
        mode    => '0550',
        content => template("bugzilla/scripts/${script_name}.erb"),
    }

    cron { 'bugzilla_communitymetrics_cron':
        command     => "cd ${bz_path} ; ./${script_name}",
        user        => $script_user,
        hour        => '0',
        minute      => '0',
        monthday    => '1',
    }
}

