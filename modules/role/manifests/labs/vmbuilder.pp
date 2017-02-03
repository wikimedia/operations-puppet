# filtertags: labs-project-openstack
class role::labs::vmbuilder {
    class { '::labs_vmbuilder':
        vmbuilder_version => '3';
    }
}
