# This define can be used to install a package from a component provided on
# our internal apt repository. Correct ordering is ensured so that repositories
# are added and apt refreshed before the packages are installed.
#
# [*component*]
#  The component name on the repository, e.g. 'component/vp9',
#
# [*packages*]
#  An array of packages to install. If the package you're installing is not
#  available in Debian or the "main" component of our repository, it's sufficient
#  to only specify the target package and have apt pull in all dependencies. If
#  however you're installing a more recent version of a package which also exists
#  in Debian main, then you also need to list the dependencies so that the pinning
#  configuration is also applied to them.
#
# [*distro*]
#  The distribution for which the packages are built, defaults to the
#  ${::lsbdistcodename}-wikimedia suite of the current distro by default.
#  If a package is specifically only available for a given distro, it can
#  also be listed like "stretch-wikimedia"
#
# [*uri*]
#  Where the packages are installed from, defaults to http://apt.wikimedia.org/wikimedia
#
# [*priority*]
#  An APT priority value. In our configuration packages in the "main" component receives
#  a default priority of 1001. If you're adding a package from a componentn which isn't
#  in Debian or which is in a higher version than what's in Debian you can simply use
#  the default value of 1001. If you're installing a package in a higher version than
#  what' in the "main" component of apt.wikimedia.org you should specify 1002.

define apt::package_from_component(
    String $component,
    Array[String] $packages,
    String $distro = "${::lsbdistcodename}-wikimedia",
    Stdlib::HTTPUrl $uri = 'http://apt.wikimedia.org/wikimedia',
    Integer $priority = 1001,
) {
    include apt

    apt::repository { "repository_${title}":
        uri        => $uri,
        dist       => $distro,
        components => $component,
        notify     => Exec["exec_apt_${title}"],
    }

    # We already pin o=Wikimedia with priority 1001
    unless $distro == "${::lsbdistcodename}-wikimedia" or $priority == 1001 {
        apt::pin { "apt_pin_${title}":
            pin      => "release c=${component}",
            priority => $priority,
            package  => join($packages, ' '),
            before   => Package[$packages],
        }
    }

    package { $packages:
        ensure  => present,
        require => [Apt::Repository["repository_${title}"], Exec["exec_apt_${title}"]],
    }

    exec {"exec_apt_${title}":
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }
}
