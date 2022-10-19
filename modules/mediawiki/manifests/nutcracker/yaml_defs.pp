# Kubernetes redis pools
# Each pool has a listening port, but currently nutcracker listens to unix sockers
# while in kubernetes each pool will be listening to a TCP port. There is no
# harm to temporarily statically define the kubernetes TCP port for each pool here

class mediawiki::nutcracker::yaml_defs(
    Wmflib::Ensure $ensure  = absent,
    Stdlib::Unixpath $path = undef,
){
    file { $path:
        ensure => $ensure,
    }
}
