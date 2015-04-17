# Class package_builder::environments
# A wrapper class for package::pbuilder_base. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::environments {
    # amd64 architecture
    package_builder::pbuilder_base { 'precise-amd64':
        distribution => 'precise',
        components   => 'main universe',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/ubuntu',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'trusty-amd64':
        distribution => 'trusty',
        components   => 'main universe',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/ubuntu',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'jessie-amd64':
        distribution => 'jessie',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'sid-amd64':
        distribution => 'sid',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    # i386 architecture
    package_builder::pbuilder_base { 'precise-i386':
        distribution => 'precise',
        components   => 'main universe',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/ubuntu',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'trusty-i386':
        distribution => 'trusty',
        components   => 'main universe',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/ubuntu',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'jessie-i386':
        distribution => 'jessie',
        components   => 'main',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'sid-i386':
        distribution => 'sid',
        components   => 'main',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
}
