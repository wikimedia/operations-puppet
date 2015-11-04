# == Class: apt::backports
#
# Enable backports with a lower priority (50) than that of any installed
# packages. This makes packages that are only available in backports
# installable, but it prevents already-installed packages from being
# upgraded automatically if a newer version exists in backports.
#
class apt::backports {
    $backports_repository_uri = $::lsbdistid ? {
        Debian => 'http://mirrors.wikimedia.org/debian',
        Ubuntu => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
    }

    $backports_repository_components = $::lsbdistid ? {
        Debian => 'main',
        Ubuntu => 'main restricted universe multiverse',
    }

    apt::repository { "${::lsbdistcodename}-backports":
        uri        => $backports_repository_uri,
        dist       => "${::lsbdistcodename}-backports",
        components => $backports_repository_components,
    }

    apt::pin { "${::lsbdistcodename}-backports":
        pin      => "release a=${::lsbdistcodename}-backports",
        priority => 50,
        package  => '*',
    }

    Class['::apt::backports'] -> Package <| provider == 'apt' |>
}
