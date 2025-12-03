# SPDX-License-Identifier: Apache-2.0
# @summary Converts the given IP ranges into a Googlebot format hash
# @param prefixes IP prefixes to include in the file
# @param created RFC 3339 datetime to include as the created timestamp
function wmflib::googlebot_ranges_json (
  Array[Wmflib::IP::Address::CIDR] $prefixes,
  String[1]                        $created,
) >> Hash[String[1], Any] {
  {
    'prefixes'     => $prefixes.map |$prefix| {
      $version = wmflib::ip_family($prefix)
      $key = "ipv${version}Prefix"
      $ret = {$key => $prefix}
      $ret
    },
    'creationTime' => $created,
  }
}
