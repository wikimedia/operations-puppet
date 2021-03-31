# Class package_builder::environments
# A wrapper class for package::pbuilder_base. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::environments(
    Stdlib::Unixpath                      $basepath       = '/var/cache/pbuilder',
    Hash[Debian::Codename, Array[String]] $extra_packages = {}
) {
    package_builder::pbuilder_base { 'jessie-amd64':
        distribution   => 'jessie',
        components     => 'main',
        architecture   => 'amd64',
        mirror         => 'http://mirrors.wikimedia.org/debian',
        keyring        => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath       => $basepath,
        extra_packages => pick_default($extra_packages['jessie'], [])
    }
    package_builder::pbuilder_base { 'stretch-amd64':
        distribution   => 'stretch',
        components     => 'main',
        architecture   => 'amd64',
        mirror         => 'http://mirrors.wikimedia.org/debian',
        keyring        => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath       => $basepath,
        extra_packages => pick_default($extra_packages['stretch'], [])
    }
    package_builder::pbuilder_base { 'buster-amd64':
        distribution   => 'buster',
        components     => 'main',
        architecture   => 'amd64',
        mirror         => 'http://mirrors.wikimedia.org/debian',
        keyring        => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath       => $basepath,
        extra_packages => pick_default($extra_packages['buster'], [])
    }
    package_builder::pbuilder_base { 'bullseye-amd64':
        distribution   => 'bullseye',
        components     => 'main',
        architecture   => 'amd64',
        mirror         => 'http://mirrors.wikimedia.org/debian',
        keyring        => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath       => $basepath,
        extra_packages => pick_default($extra_packages['bullseye'], [])
    }
    package_builder::pbuilder_base { 'sid-amd64':
        distribution       => 'sid',
        distribution_alias => 'unstable',
        components         => 'main',
        architecture       => 'amd64',
        mirror             => 'http://mirrors.wikimedia.org/debian',
        keyring            => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath           => $basepath,
        extra_packages     => pick_default($extra_packages['sid'], [])
    }
}
