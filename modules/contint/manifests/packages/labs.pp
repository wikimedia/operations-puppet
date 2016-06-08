# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    Package['puppet-lint'] -> Class['contint::packages::labs']

    require contint::packages::apt

    include contint::packages

    include ::mediawiki::packages
    include ::mediawiki::packages::multimedia  # T76661

    # Fonts needed for browser tests screenshots (T71535)
    if os_version('ubuntu >= trusty || Debian >= jessie') {
        include mediawiki::packages::fonts
    }

    include ::contint::packages::analytics
    include ::contint::packages::java
    include ::contint::packages::javascript
    include ::contint::packages::php
    include ::contint::packages::python
    include ::contint::packages::ruby

    include phabricator::arcanist

    # Database related
    package { [
        'mysql-server',
        'sqlite3',
        ]:
        ensure => present,
    }

    # Development packages
    package { [
        'librsvg2-2',

        'asciidoc',

        'pep8',
        'python-simplejson',  # For mw/ext/Translate among others

        'luajit',
        'libevent-dev',  # PoolCounter daemon
        'liblua5.1-0-dev',
        'g++',
        'libthai-dev',

        'doxygen',
        'python-sphinx',  # python documentation
        ]:
        ensure => present,
    }

    # For Sphinx based documentation contain blockdiag diagrams
    require_package('libjpeg-dev')

    # For mediawiki/extensions/Collection/OfflineContentGenerator/bundler
    require_package('zip')

    package { [
        'ocaml-nox',
        ]:
        ensure => present;
    }

    if os_version('ubuntu >= trusty') {
        # Work around PIL 1.1.7 expecting libs in /usr/lib T101550
        file { '/usr/lib/libjpeg.so':
            ensure => link,
            target => '/usr/lib/x86_64-linux-gnu/libjpeg.so',
        }
        file { '/usr/lib/libz.so':
            ensure => link,
            target => '/usr/lib/x86_64-linux-gnu/libz.so',
        }

        package { [
            # Android SDK
            'gcc-multilib',
            'lib32z1',
            'lib32stdc++6',
            # Android emulation
            'qemu',
            ]: ensure => present,
        }

        exec {'jenkins-deploy kvm membership':
            unless  => "/bin/grep -q 'kvm\\S*jenkins-deploy' /etc/group",
            command => '/usr/sbin/usermod -aG kvm jenkins-deploy',
        }
    }

    if os_version( 'debian >= jessie') {
        include ::contint::packages::ops
    }
}
