# Class package_builder::environments
# A wrapper class for package::pbuilder_base. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::environments(
    Stdlib::Unixpath $basepath='/var/cache/pbuilder',
) {
    # amd64 architecture
    package_builder::pbuilder_base { 'trusty-amd64':
        distribution => 'trusty',
        components   => 'main universe',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/ubuntu',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
        basepath     => $basepath,
    }
    package_builder::pbuilder_base { 'jessie-amd64':
        distribution => 'jessie',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath     => $basepath,
    }
    package_builder::pbuilder_base { 'stretch-amd64':
        distribution => 'stretch',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath     => $basepath,
    }
    package_builder::pbuilder_base { 'buster-amd64':
        distribution => 'buster',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath     => $basepath,
    }
    package_builder::pbuilder_base { 'sid-amd64':
        distribution       => 'sid',
        distribution_alias => 'unstable',
        components         => 'main',
        architecture       => 'amd64',
        mirror             => 'http://mirrors.wikimedia.org/debian',
        keyring            => '/usr/share/keyrings/debian-archive-keyring.gpg',
        basepath           => $basepath,
    }
}
