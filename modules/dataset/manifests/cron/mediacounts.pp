# == Class dataset::cron::mediacounts
# Copies over the mediacounts files
# from an rsyncable location.
class dataset::cron::mediacounts(
    $source,
    $enable      = true,
    $destination = '/data/xmldatadumps/public/other/mediacounts',
    $user        = 'datasets',
)
{
    $ensure = $enable ? {
        true    => 'present',
        default => 'absent',
    }

    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    cron { 'mediacounts':
        ensure      => $ensure,
        command     => "/usr/bin/rsync -rt --delete --chmod=go-w ${source}/ ${destination}/",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '41',
        require     => User[$user],
    }
}
