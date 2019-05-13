# This define allows you to monitor for improperly owned (usually root)
# directories that need manual cleanup to unblock other users
#
# == Parameters
# $title    - Used as directory to check in
# $uid      - User id to check for
# $gid      - Group id to check for
# $interval - How often to check (default 10)
# $timeout  - How long to wait before giving up (default 10s)
define monitoring::icinga::bad_directory_owner (
    $uid      = 0,
    $gid      = 0,
    $interval = 10,
    $timeout  = 10,
    ) {

    $safe_title = regsubst($title, '\/', '_', 'G')
    $filename = "/usr/local/lib/nagios/plugins/check${safe_title}-bad-owner"

    file { $filename:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('monitoring/check_dir-not-bad-owner.erb'),
    }

    nrpe::monitor_service { "${safe_title}_owned":
        description    => "Improperly owned (${uid}:${gid}) files in ${title}",
        nrpe_command   => $filename,
        check_interval => $interval,
        timeout        => $timeout,
        require        => File[$filename],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/bad_directory_owner',
    }
}
