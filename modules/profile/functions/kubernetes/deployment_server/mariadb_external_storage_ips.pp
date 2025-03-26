# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::mariadb_external_storage_ips(String $datacenter) >> Array[Stdlib::IP::Address, 0] {
  $pql = @("PQL")
    nodes[certname] {
      resources {
        type = 'Class' and
        title = 'Role::Mariadb::Core' and
        certname ~ 'es' and
        certname ~ '${datacenter}.wmnet'
      }
      order by certname
    }
    | PQL
  $res = wmflib::puppetdb_query($pql)
  if ($res == undef) {
    []
  } else {
    $res.map |$mariadb_node| {
      $mariadb_hostname = $mariadb_node['certname'];
      ipresolve($mariadb_hostname, 4)
    }.reduce([]) |$memo, $ips| {
      $memo << $ips
    }
  }
}
