3.0.0:
 * Add an optional lambda argument that is called and returned instead if
   the lookup raises an exception or returns an empty result.
 * Change return format on dns_srv and dns_mx to an array of hashes. This
   removes the need for the optional field parameter. That can be fetched using
   the map function in Puppet 4.x+ instead.
 * Use the Puppet 4 function API.

2.0.1:
 * correctly convert array of Resolv::IPv4 or Resolv::IPv6 to array strings

2.0.0:
 * Raise an exception on empty replies.
