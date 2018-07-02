# == Class: mediawiki::jobrunner
#
# Temporary class to clean up the jobrunner scripts
class mediawiki::jobrunner {
    # Remove most of what is created by the scap target
    sudo::user { 'scap_mwdeploy_jobrunner':
        ensure     => absent,
        privileges => [],
    }
    file { '/srv/deployment/jobrunner':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/etc/default/jobrunner':
        ensure => absent,
    }


    file { '/etc/jobrunner':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    # We declare the service, but override its status with
    # $service_ensure
    base::service_unit { 'jobrunner':
        ensure         => absent,
        systemd        => 'test',
        service_params => {},
    }

    base::service_unit { 'jobchron':
        ensure         => absent,
        systemd        => 'test',
        service_params => {},
    }

    file { ['/etc/logrotate.d/mediawiki_jobrunner', '/etc/logrotate.d/mediawiki_jobchron']:
        ensure => absent
    }

    rsyslog::conf { 'jobrunner':
        ensure   => absent,
        priority => 20,
    }
}
