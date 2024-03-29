# Define an anycast VIP and the command to use as healthcheck
type Wmflib::Advertise_vip = Struct[{
  'ensure'         => Enum['present', 'absent'],
  'address'        => Stdlib::IP::Address::V4::Nosubnet,
  'check_cmd'      => String,
  'service_type'   => String,
  'check_fail'     => Optional[Integer],
  'address_ipv6'   => Optional[Stdlib::IP::Address::V6::Nosubnet],
  'check_cmd_ipv6' => Optional[String],
}]
