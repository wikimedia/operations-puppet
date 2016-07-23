# == Class contint::packages::androidsdk
#
# Provides dependencies for the Android SDK which is installed by the Jenkins
# plugin Android Emulator.
class contint::packages::androidsdk {
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
