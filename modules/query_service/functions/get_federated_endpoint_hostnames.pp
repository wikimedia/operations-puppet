# SPDX-License-Identifier: Apache-2.0
# Return the list of hostnames from the definition of internal federated endpoints
function query_service::get_federated_endpoint_hostnames(
  Optional[Hash[Stdlib::HTTPSUrl, Array[Stdlib::HTTPSUrl]]] $endpoints) >> Optional[String]
{
  if $endpoints and $endpoints != {} {
    $internal_federated_hosts = $endpoints.keys.map |$u| {
      $u ? {
        /^https:\/\/([^\/:]+)[:\/]?/ => $1,
        default => fail("Unparseable URL ${u}")
      }
    }.join(',')
  } else {
    $internal_federated_hosts = undef
  }
  $internal_federated_hosts
}
