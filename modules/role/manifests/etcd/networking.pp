# Role to set up an etcd cluster for virtual networking
# stacks as flannel and calico.
class role::etcd::networking {
    include ::standard
    include ::base::firewall
    include ::profile::etcd
}
