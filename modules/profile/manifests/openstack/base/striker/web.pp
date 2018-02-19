class profile::openstack::base::striker::web {
    include ::striker::apache
    include ::striker::uwsgi
    require ::passwords::striker
}
