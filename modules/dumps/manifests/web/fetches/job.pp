# == Define dumps::web::fetches
# Regularly copies files from $source to $destination.
#
# == Parameters
#
# [*ensure*]
#   Ensure status of cron job. ensure => absent will not remove any existent data.
#
define dumps::web::fetches::job(
    $source,
    $destination,
    $delete      = true,
    $exclude     = undef,
    $user        = undef,
    $mailto      = 'ops-dumps@wikimedia.org',
    $hour        = undef,
    $minute      = undef,
    $month       = undef,
    $monthday    = undef,
    $weekday     = undef,
    $ensure      = 'present',
) {
    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    $delete_option = $delete ? {
        true    => '--delete',
        default => ''
    }

    $exclude_option = $exclude ? {
        undef   => '',
        default => " --exclude ${exclude}"
    }

    cron { "dumps-fetch-${title}":
        ensure      => $ensure,
        # Run command via bash instead of sh so that $source can be fancier
        # wildcards or globs (e.g. /path/to/{dir1,dir1}/ok/data/ )
        command     => "bash -c '/usr/bin/rsync -rt ${delete_option}${exclude_option} --chmod=go-w ${source}/ ${destination}/'",
        environment => "MAILTO=${mailto}",
        user        => $user,
        require     => User[$user],
        minute      => $minute,
        hour        => $hour,
        month       => $month,
        monthday    => $monthday,
        weekday     => $weekday,
    }
}
