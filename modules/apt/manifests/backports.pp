# == Class: apt::backports
#
# Enable backports with a lower priority (50) than that of any installed
# packages. This makes packages that are only available in backports
# installable, but it prevents already-installed packages from being
# upgraded automatically if a newer version exists in backports.
#
class apt::backports {
    $distro = downcase($::lsbdistid)

    $components = $distro ? {
        debian => 'main',
        ubuntu => 'main restricted universe multiverse',
    }

    apt::repository { "${::lsbdistcodename}-backports":
        uri        => "http://mirrors.wikimedia.org/${distro}",
        dist       => "${::lsbdistcodename}-backports",
        components => $components
    } ->

    apt::pin { "${::lsbdistcodename}-backports":
        package  => '*',
        pin      => "release a=${::lsbdistcodename}-backports",
        priority => 50,
    }

    Class['::apt::backports'] -> Package <| provider == 'apt' |>
}
