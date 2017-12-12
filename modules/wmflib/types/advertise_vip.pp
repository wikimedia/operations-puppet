# Define an anycast VIP and the command to use as healthcheck
type Wmflib::Advertise_vip = Struct[{
  'address'   => Stdlib::IP::Address::V4::Nosubnet,
  'check_cmd' => String,
  'ensure'    => Enum['present', 'absent'],
}]
