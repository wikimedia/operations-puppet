# == Class: role::ve
#
# Sets up a Visual Editor performance testing rig with a headless
# Chromium instance that supports remote debugging.
#
class role::ve {
    class { 'xvfb': resolution => '1366x768x24' }
    class { 'chromium': }


    # `vbench` is a CLI tool for benchmarking VisualEditor
    # It requires `python-autobahn`.

    require_package('python-autobahn')

    file { '/usr/local/bin/vbench':
        source => 'puppet:///files/ve/vbench',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
