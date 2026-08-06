# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::mariadb_master_ips(String $profile, String $host_prefix) >> Array[Stdlib::IP::Address, 0, 2] {
  $pql = @("PQL")
    inventory[certname,facts.networking.ip,facts.networking.ip6] {
      certname ~ "${host_prefix}" and
      resources {
        type = 'Class' and
        title = '${profile}' and
        parameters.is_mariadb_replica = false
      }
      order by certname
    }
    | PQL
  $res = wmflib::puppetdb_query($pql)
  if ($res == undef or $res[0] == undef) {
    []
  } else {
    # There's only one master, so we're only taking the first result
    [$res[0]['facts.networking.ip'], $res[0]['facts.networking.ip6']]
  }
}
