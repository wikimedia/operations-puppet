# SPDX-License-Identifier: Apache-2.0
# @summary a squid acl for puppet roles
type Squid::Acl = Struct[{
    task     => Phabricator::Task,
    port     => Stdlib::Port,
    dst_type => Enum['host', 'domain'],
    src      => Array[String[1],1],
    dst      => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Host],1],
}]
