# SPDX-License-Identifier: Apache-2.0
# Adds script which Nokia devices fetch/execute during ZTP provisioning
class aptrepo::ztp_nokia () {

    file { '/srv/private/nokia':
        ensure => 'directory',
    }

    # TODO: (maybe tmp) admin password's hash
    $homer_key = secret('keyholder/homer.pub')

    file { '/srv/private/srlinux/ztp-nokia.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('aptrepo/ztp-nokia.py.erb'),
    }

# Will manage manually for now on the apt server
#    file { '/srv/private/srlinux/nokia-bootstrap.json':
#        owner   => 'root',
#        group   => 'root',
#        mode    => '0444',
#        content => template('aptrepo/nokia-bootstrap.json'),
#    }
}
