# Type for holding swift cluster metadata
type Swift::Cluster_info = Struct[{
    cluster_name => String[1],
    ring_manager => Optional[Stdlib::Host],
}]
