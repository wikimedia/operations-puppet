# Installs a script to add firmware to Debian netboot images
class profile::puppetmaster::updatenetboot {

    file { '/usr/local/sbin/update-netboot-image':
        ensure => present,
        source => 'puppet:///modules/profile/puppetmaster/update-netboot-image.sh',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    require_package('pax')
}
