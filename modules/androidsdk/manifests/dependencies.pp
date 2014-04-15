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

    # 32bit libs needed by Android SDK
    # ..but NOT just all of ia32-libs ..
    package { [
        'libstdc++6:i386',
        'libgcc1:i386',
        'zlib1g:i386',
        'libncurses5:i386',
        'libsdl1.2debian:i386',
        'libswt-gtk-3.5-java'
        ]: ensure => $ensure;
    }

}
