# Basic ipblock to describe services.
# If modified, update also spicerack.service.ServiceIPs
type Wmflib::Service::Ipblock = Hash[String[1], Stdlib::Ip::Address]
