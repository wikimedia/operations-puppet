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

    file { $filename:
        ensure  => present,
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0555',
        content => template('monitoring/check_dir-not-bad-owner.erb'),
    }

    nrpe::monitor_service { "${safe_title}_owned":
        description  => "Improperly owned (${uid}:${gid}) files in ${title}",
        nrpe_command => $filename,
        retries      => $interval,
        require      => File[$filename],
    }
}
