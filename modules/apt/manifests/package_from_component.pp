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
#  This parameter can also accept a Hash[String, String] which allows you to override
#  the ensure parameter and means you are able to create resources like the following
#  however this syntax should be used with caution as ties software updates to a git
#  commit to bump the version:
#
#    apt::package_from_component { 'foobar':
#      component => 'component/foobar',
#      packages => { 'foo' => 'present', 'bar' => '1.1.7-1~bpo10+1'}
#    }
#
# [*distro*]
#  The distribution for which the packages are built, defaults to the
#  ${::lsbdistcodename}-wikimedia suite of the current distro by default.
#  If a package is specifically only available for a given distro, it can
#  also be listed like "bookworm-wikimedia"
#
# [*uri*]
#  Where the packages are installed from, defaults to http://apt.wikimedia.org/wikimedia
#
# [*priority*]
#  An APT priority value. In our configuration, packages in the "main" component receive
#  a default priority of 1001. If you're adding a package from a component which isn't
#  in Debian or which is in a higher version than what's in Debian, you can simply use
#  the default value of 1001. If you're installing a package in a higher version than
#  what's in the "main" component of apt.wikimedia.org you should specify 1002.
#
#  [*ensure_packages*]
#   If true, the default, also install the packages array with ensure_packages($packages)

define apt::package_from_component(
    String          $component,
    Variant[Array[String],Hash[String,String]] $packages        = [$name],
    String                                     $distro          = "${::lsbdistcodename}-wikimedia",
    Stdlib::HTTPUrl                            $uri             = 'http://apt.wikimedia.org/wikimedia',
    Integer                                    $priority        = 1001,
    Boolean                                    $ensure_packages = true,
) {
    include apt

    $exec_before = $ensure_packages ? {
        false => undef,
        default => $packages ? {
            Hash    => Package[$packages.keys],
            default => Package[$packages],
        }
    }

    # We intentionally don't use the exec defined in the apt class to avoid
    # dependency cycles. We require the apt class to be applied before any
    # packages are installed, so we don't want to also require this define to be
    # applied before the apt class as we may need to install a package before
    # this define.
    exec {"apt_package_from_component_${title}":
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
        before      => $exec_before,
    }

    # Starting with Bookworm the Debian installer defaults to using the signed-by
    # notation in apt-setup, also apply the same for the puppetised Wikimedia
    # repository.
    # The signed-by notation allows to specify which repository key is used
    # for which repository (previously they applied to all repos)
    # https://wiki.debian.org/DebianRepository/UseThirdParty
    if debian::codename::ge('bookworm'){
        $wikimedia_apt_keyfile = 'puppet:///modules/install_server/autoinstall/keyring/wikimedia-archive-keyring.gpg'
    } else {
        $wikimedia_apt_keyfile = undef
    }

    apt::repository { "repository_${title}":
        uri        => $uri,
        dist       => $distro,
        components => $component,
        keyfile    => $wikimedia_apt_keyfile,
        notify     => Exec["apt_package_from_component_${title}"],
    }

    # We already pin o=Wikimedia with priority 1001
    unless $distro == "${::lsbdistcodename}-wikimedia" and $priority == 1001 {
        apt::pin { "apt_pin_${title}":
            pin      => "release c=${component}",
            priority => $priority,
            package  => join($packages, ' '),
            notify   => Exec["apt_package_from_component_${title}"],
        }
        if $ensure_packages {
            Apt::Pin["apt_pin_${title}"] {
                before   => Package[$packages],
            }
        }
    }

    if $ensure_packages {
        if $packages =~ Hash {
            $packages.each |$pkg, $ensure| {
                ensure_packages($pkg, {ensure => $ensure})
            }
        } else {
            ensure_packages($packages)
        }
    }
}
