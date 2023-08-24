# == Definition pbuilder_base
#
# Parameters:
#
# [*mirror*]
# Apt mirror to bootstrap the image from.
# Default: 'http://mirrors.wikimedia.org/debian
#
# [*distribution*]
# Target Distribution (e.g: buster, bullseye, etc)
# Default: 'bullseye'
#
# [*components*]
# List of distribution components to install. Passed as is to pbuilder, space
# separated.
# Default: 'main'
#
# [*architecture*]
# Target architecture (e.g: i386, amd64).
# Default: 'amd64'
#
# [*basepath*]
# Directory that holds the cow images.
# Default: '/var/cache/pbuilder'
#
# [*keyring*]
# Path to an additional keyring to use. Passed to debootstrap --keyring option.
# Example: '/usr/share/keyrings/debian-archive-keyring.gpg'.
# Default: undef
#
# [*distribution_alias*]
# Alias for the distribution. Will create a symbolic link, that is merely a
# workaround to recognize both 'sid' and 'unstable' while generating only a
# single cow image.
# Default: undef
#
# [*extra_packages*]
# An array of additional packages to add to the cowbuilder images
# Default: []
define package_builder::pbuilder_base(
    Stdlib::Httpurl            $mirror             = 'http://mirrors.wikimedia.org/debian',
    String                     $distribution       = 'bullseye',
    Optional[String]           $distribution_alias = undef,
    String                     $components         = 'main',
    String                     $architecture       = 'amd64',
    Stdlib::Unixpath           $basepath           = '/var/cache/pbuilder',
    Array                      $extra_packages     = [],
    Optional[Stdlib::Unixpath] $keyring            = undef,
) {
    if $keyring {
        $arg = "--debootstrapopts --keyring=${keyring}"
    } else {
        $arg = ''
    }

    $cowdir = "${basepath}/base-${distribution}-${architecture}.cow"
    $_extra_packages = $extra_packages.empty ? {
        true    => '',
        default => "--extrapackages \"${extra_packages.join(' ')}\"",
    }

    $command = @("COMMAND"/L)
    /usr/sbin/cowbuilder --create \
    --mirror ${mirror} \
    --distribution ${distribution} \
    --components "${components}" \
    --architecture ${architecture} \
    --basepath "${cowdir}" \
    ${_extra_packages} \
    --debootstrapopts --variant=buildd \
    ${arg}
    | COMMAND

    file{ "/var/cache/pbuilder/aptcache/${distribution}-${architecture}":
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    exec { "cowbuilder_init_${distribution}-${architecture}":
        command => $command,
        creates => $cowdir,
        require => File["/var/cache/pbuilder/aptcache/${distribution}-${architecture}"]
    }

    # --no-cowdancer-update is used to workaround #970555.
    # Can be removed after the upgrade to bullseye
    $update_command = "/usr/sbin/cowbuilder --update \
                    --no-cowdancer-update \
                    ${_extra_packages} \
                    --basepath \"${cowdir}\""

    systemd::timer::job { "cowbuilder_update_${distribution}-${architecture}":
        ensure      => present,
        user        => 'root',
        description => 'updates cowbuilder base images',
        command     => $update_command,
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 07:34:00'},
    }
    if $distribution_alias {
        file { "${basepath}/base-${distribution_alias}-${architecture}.cow":
            ensure => link,
            target => $cowdir,
        }
    }
}
