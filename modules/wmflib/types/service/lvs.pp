# @type Wmflib::Service::Lvs
# Define all the variables related to configuring LVS.
# If modified, update also spicerack.service.ServiceLVS
# @param [Boolean] enabled Is the service enabled or not on the load balancers
# @param [Enum] class lvs class of the service
# @param [Optional[Enum]] scheduler the IPVS scheduler to use when load-balancing the service. Defaults to 'wrr'.
# @param [Struct] conftool  the conftool metadata for the service.
# @param [Float[0.0, 1.0]] depool_threshold  the percentage of the cluster that will be kept pooled by Pybal even if checks fail
# @param [Hash] monitors
#    Which Pybal monitors to configure. For details, see the Pybal documentation. Configuration options are written as key: value
# @param [Optional[Boolean]] bgp  Whether to advertise the service via bgp, or not. Defaults to true
# @param [Optional[Enum]] protocol  Whether the service uses tcp or udp. Defaults to 'tcp'.
# @param [Optional[Array[Wmflib::Sites]] ipip_encapsulation  List of sites where the real servers receive traffic from the load balancers using IPIP encapsulation. Defaults to an empty array
type Wmflib::Service::Lvs = Struct[{
    'enabled'            => Boolean,
    'class'              => Enum['low-traffic', 'high-traffic1', 'high-traffic2'],
    'scheduler'          => Optional[Enum['rr', 'wrr', 'lc', 'wlc', 'lblc', 'lblcr', 'dh', 'sh', 'sed', 'nq', 'mh']],
    'conftool'           => Struct[{'cluster' => String[1], 'service' => String[1]}],
    'depool_threshold'   => Float[0.0, 1.0],
    'monitors'           => Optional[Hash[Enum['ProxyFetch', 'IdleConnection', 'UDP'], Hash]],
    'bgp'                => Optional[Boolean],
    'protocol'           => Optional[Enum['tcp', 'udp']],
    'ipip_encapsulation' => Optional[Array[Wmflib::Sites]],
}]
