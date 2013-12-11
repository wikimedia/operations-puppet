# == Class: ocg::decommission
#
# This class automates the process of retiring an OCG Collection render
# node. It will shut down running services, clean up temporary files,
# and remove configuration data.
#
class ocg::decommission (
    $temp_dir = '/srv/deployment/ocg/tmp'
) {
    service { 'ocg':
        ensure   => stopped,
        provider => upstart,
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
        ensure  => absent,
        purge   => true,
        force   => true,
    }

    deployment::target { 'ocg':
        require => Service['ocg'],
        ensure  => absent,
    }
}
