# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::mariadb_external_storage_ips(String $datacenter) >> Array[Stdlib::IP::Address, 0] {
  $pql = @("PQL")
    inventory[certname,facts.networking.ip] {
      certname ~ 'es' and
      certname ~ "${datacenter}.wmnet" and
      resources {
        type = 'Class' and
        title = 'Role::Mariadb::Core'
      }
      order by certname
    }
    | PQL
  $res = wmflib::puppetdb_query($pql)
  if ($res == undef) {
    []
  } else {
    $res.map |$mariadb_node| {
      $mariadb_node['facts.networking.ip']
    }.reduce([]) |$memo, $ips| {
      $memo << $ips
    }
  }
}
