# == Class androidsdk::dependencies
#
# Class installing prerequisites to the Android SDK.
#
# The SDK itself need to be installed manually for now.
#
# Help link: http://developer.android.com/sdk/installing.html
#
# == Parameters
#
# [*ensure*] puppet stanza passed to package definitions. Default: 'present'
class androidsdk::dependencies( $ensure = 'present' ) {

    if ! defined(Package['ant']) {
        package { 'ant':
            ensure => $ensure,
        }
    }

    package { 'openjdk-7-jdk':
        ensure => $ensure,
    }

    # 32bit compat libraries needed by AndroidSDK
    # They have different names in precise and trusty
    if $::lsbdistcodename == 'precise' {
        package { [
            'libgcc1:i386',
            'libncurses5:i386',
            'libstdc++6:i386',
            'zlib1g:i386',
            ]: ensure => $ensure
        }
    } else {
        package { [
            'lib32stdc++6',
            'lib32z1',
            'lib32ncurses5',
            'lib32bz2-1.0',
            ]: ensure => $ensure
        }
    }
}
