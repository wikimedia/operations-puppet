# SPDX-License-Identifier: Apache-2.0
type Wmflib::Dumps::Mirror = Struct[{
  url         => Stdlib::HTTPUrl,
  hostname    => Stdlib::Host,
  ipv4        => Array[Stdlib::Host],
  ipv6        => Array[Stdlib::Host],
  contactname => String[1],
  contactaddy => Stdlib::Email,
  institution => String[1],
  addedby     => String[1],
  addeddate   => String[1],
  active      => Stdlib::Yes_no,
}]
