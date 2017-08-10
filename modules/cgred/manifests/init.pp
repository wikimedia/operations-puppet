# Establishing cgroups and enforcing them using cgrules engine
#
# This module is oriented towards the workflow of defining
# cgroups and settings by logical unit and using the
# cgrulesengd to enforce.  The init script for cgrulesengd
# applies cgroups to this effect.
#

class cgred {

    package { [
        'cgroup-bin',
        'libpam-cgroup']:
            ensure => present;
    }

    file { [
        '/etc/cgconfig.d/',
        '/etc/cgrules.d/']:
            ensure  => directory,
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
            recurse => true,
            purge   => true,
    }

    file { '/etc/cgrules.d/README':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/cgred/cgrules_readme',
        require => File['/etc/cgrules.d/'],
    }

    base::service_unit { 'cgrulesengd':
        ensure         => present,
        sysvinit       => sysvinit_template('cgrulesengd'),
        refresh        => true,
        service_params => {
            hasrestart => true,
        },
        require        => File['/etc/cgrules.d/'];
    }
}
