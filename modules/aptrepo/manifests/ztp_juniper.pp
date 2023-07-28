# SPDX-License-Identifier: Apache-2.0
# Adds script which Juniper devices fetch/execute during ZTP provisioning
class aptrepo::ztp_juniper () {
    $homer_key = secret('keyholder/homer.pub')
    file { '/srv/private/junos/ztp-juniper.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('aptrepo/ztp-juniper.sh.erb'),
    }
}
