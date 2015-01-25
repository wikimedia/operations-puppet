# == Class: role::ve
#
# Sets up a Visual Editor performance testing rig with a headless
# Chromium instance that supports remote debugging.
#
class role::ve( $ensure = present ) {
    class { 'xvfb':
        ensure     => $ensure,
        resolution => '1366x768x24',
    }

    class { 'chromium':
        ensure => $ensure,
    }
}
