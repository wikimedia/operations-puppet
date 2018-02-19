class profile::openstack::base::striker::web {
    class { '::striker::apache': }
    class { '::striker::uwsgi': }
    require ::passwords::striker
}
