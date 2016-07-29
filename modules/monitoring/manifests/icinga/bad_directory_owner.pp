# This define allows you to monitor for improperly owned (usually root)
# directories that need manual cleanup to unblock other users
#
# == Parameters
# $title    - Used as directory to check in
# $uid      - User id to check for
# $gid      - Group id to check for
# $interval - How often to check (default 10)
define monitoring::icinga::bad_directory_owner (
    $uid      = 0,
    $gid      = 0,
    $interval = 10
    ) {

    $safe_title = regsubst($title, '\/', '_', 'G')
    $filename = "/usr/local/lib/nagios/plugins/check_${safe_title}-needs-merge"

    file { "check_${safe_title}_needs_merge":
        ensure  => present,
        path    => $filename,
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0555',
        content => template('monitoring/check_dir-not-bad-owner.erb')
    }

    nrpe::monitor_service { "${title_dir}_owned":
        description  => "Improperly owned files in ${title}",
        nrpe_command => $filename,
        retries      => $interval,
        require      => File["check_${safe_title}_needs_merge"]
    }
}
