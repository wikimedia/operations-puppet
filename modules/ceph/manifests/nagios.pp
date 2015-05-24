# Class: ceph::nagios
#
# This class sets up an NRPE service check for Ceph healthiness.
#
# Parameters:
#
# Actions:
#     Creates a separate Ceph admin key with minimum permissions
#     Installs a Nagios plugin to /usr/lib/nagios/plugins
#     Sets up the NRPE configuration for the check
#     Exports a Nagios monitor service check
#
# Requires:
#     Class[ceph]
#     Package['nagios-nrpe-server']
#     Package['nagios-plugins-basic']
#     Define['nrpe::monitor_service']
#
# Sample Usage:
#     include ceph::nagios

class ceph::nagios(
    $ensure='present',
    $cluster='ceph',
    $entity='nagios',
) {
    Class['ceph'] -> Class['ceph::nagios']

    $keyring = "/var/lib/ceph/nagios/${cluster}.keyring"

    case $ensure {
        present: {
            $ensure_dir = 'directory'
            File['/var/lib/ceph/nagios'] ->  Ceph::Key[$entity]
        }
        absent: {
            $ensure_dir = 'absent'
            # broken due to autorequire bug,
            # http://projects.puppetlabs.com/issues/14518
            #Ceph::Key[$entity] -> File['/var/lib/ceph/nagios']
        }
        default: {
            fail("${name} ensure parameter must be absent or present")
        }
    }

    file { '/var/lib/ceph/nagios':
        ensure => $ensure_dir,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        backup => false,
        force  => true,
    }

    ceph::key { $entity:
        ensure  => $ensure,
        keyring => $keyring,
        caps    => 'mon "allow r"',
        owner   => 'root',
        group   => 'nagios',
        mode    => '0440',
        require => Package['nagios-nrpe-server'], # for the nagios group
    }

    $nagios_plugin_path = '/usr/lib/nagios/plugins/check_ceph_health'

    file { $nagios_plugin_path:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('ceph/check_ceph_health.erb'),
        # nagios-plugins-basic for the dir /usr/lib/nagios/plugins, ewww.
        require => Package['nagios-plugins-basic'],
    }

    nrpe::monitor_service { 'ceph_health':
        ensure       => $ensure,
        description  => 'Ceph',
        nrpe_command => $nagios_plugin_path,
    }
}
