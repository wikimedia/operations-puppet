class openstack::serverpackages::newton::stretch(
){
    apt::repository { 'openstack-mitaka-jessie':
        ensure => 'absent'
    }
}
