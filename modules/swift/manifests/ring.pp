# SPDX-License-Identifier: Apache-2.0
class swift::ring (
    String $swift_cluster,
) {
    file { '/usr/local/bin/swift_check_ring_tarball.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/${module_name}/swift_check_ring_tarball.sh",
    }

    wmflib::dir::mkdir_p('/var/spool/swift_ring')

    # lint:ignore:puppet_url_without_modules
    file { '/var/spool/swift_ring/rings.tar.bz2':
        ensure       => present,
        source       => "puppet:///volatile/swift/${swift_cluster}/new_rings.tar.bz2",
        show_diff    => false,
        validate_cmd => '/usr/local/bin/swift_check_ring_tarball.sh %',
    }
    exec { 'tar -xf /var/spool/swift_ring/rings.tar.bz2 --one-top-level=/etc/swift':
        path        => '/usr/bin:/bin',
        refreshonly => true,
        subscribe   => File['/var/spool/swift_ring/rings.tar.bz2'],
    }
    # lint:endignore
}
