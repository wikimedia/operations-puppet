# == Class: ocg_collection::decommission
#
# This class automates the process of retiring an OCG Collection render
# node. It will shut down running services, clean up temporary files,
# and remove configuration data.
#
class ocg_collection::decommission (
    $temp_dir = '/tmp/ocg_collection'
) {
    exec { 'initctl emit ocg-collection.stop':
        before => File['/etc/init/ocg-collection.conf'],
    }

    file {
        [
            '/etc/init/ocg-collection.conf',
            '/etc/mw-collection-ocg.js',
        ]:
        ensure  => absent,
        purge   => true,
        force   => true
    }
    
    file {
        after   => File['/etc/init/ocg-collection.conf'],
        path    => $temp_dir,
        ensure  => absent,
        purge   => true,
        force   => true
    }

    deployment::target { 'ocg-collection':
        after   => File['/etc/init/ocg-collection.conf'],
        ensure  => absent,
    }
}
