# Role to set up an etcd cluster for virtual networking
# stacks as flannel and calico.
class role::etcd::networking {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::etcd
}
