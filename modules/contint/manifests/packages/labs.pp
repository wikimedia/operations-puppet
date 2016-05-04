# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    Package['puppet-lint'] -> Class['contint::packages::labs']

    require contint::packages::apt

    include contint::packages

    # Fonts needed for browser tests screenshots (T71535)
    if os_version('ubuntu >= trusty || Debian >= jessie') {
        include mediawiki::packages::fonts
    }

    include ::contint::packages::javascript
    include ::contint::packages::php
    include ::contint::packages::python
    include ::contint::packages::ruby

    include phabricator::arcanist

    # For mediawiki/extensions/Collection/OfflineContentGenerator/bundler
    require_package('zip')

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
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
