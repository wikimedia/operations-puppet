class openstack::cinder::backup (
    String  $version,
    Boolean $active,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"
    require "openstack::cinder::config::${version}"

    ensure_packages(['cinder-backup'])

    openstack::patch { '/usr/lib/python3/dist-packages/cinder/backup/api.py':
        source  => "puppet:///modules/openstack/${version}/cinder/hacks/backup/api.py.patch",
        require => Package['cinder-backup'],
        notify  => Service['cinder-backup'],
    }

    service { 'cinder-backup':
        ensure    => $active,
        subscribe => Class["openstack::cinder::config::${version}"],
    }
}
