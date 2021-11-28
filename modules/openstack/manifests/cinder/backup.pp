class openstack::cinder::backup (
    String  $version,
    Boolean $active,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"
    ensure_packages('cinder-backup')
    require "openstack::cinder::config::${version}"

    service { 'cinder-backup':
        ensure    => $active,
        subscribe => Class["openstack::cinder::config::${version}"],
    }
}
