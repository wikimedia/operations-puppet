# SPDX-License-Identifier: Apache-2.0
# Installs a script to add firmware to Debian netboot images
class profile::puppetmaster::updatenetboot {

    file { '/usr/local/sbin/update-netboot-image':
        ensure => present,
        source => 'puppet:///modules/profile/puppetserver/update-netboot-image.sh',
        mode   => '0544',
    }

    ensure_packages('pax')
}
