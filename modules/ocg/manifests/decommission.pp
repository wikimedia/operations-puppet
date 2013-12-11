# == Class: ocg::decommission
#
# This class automates the process of retiring an OCG Collection render
# node. It will shut down running services, clean up temporary files,
# and remove configuration data.
#
class ocg_collection::decommission (
    $temp_dir = '/tmp/ocg'
) {
    exec { 'initctl emit ocg.stop':
        before => File['/etc/init/ocg.conf'],
        before => File[$temp_dir],
    }

    file { [
            '/etc/init/ocg.conf',
            '/etc/ocg'
        ]:
        ensure  => absent,
        purge   => true,
        force   => true,
    }

    file { $temp_dir:
        after   => File['/etc/init/ocg.conf'],
        path    => $temp_dir,
        ensure  => absent,
        purge   => true,
        force   => true,
    }

    deployment::target { 'ocg':
        after   => File['/etc/init/ocg.conf'],
        ensure  => absent,
    }
}

