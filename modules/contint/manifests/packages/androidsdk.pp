# == Class contint::packages::androidsdk
#
# Provides dependencies for the Android SDK which is installed by the Jenkins
# plugin Android Emulator.
contint::packages::androidsdk {
    package { [
        # Android SDK
        'gcc-multilib',
        'lib32z1',
        'lib32stdc++6',
        # Android emulation
        'qemu',
        ]: ensure => present,
    }
}
