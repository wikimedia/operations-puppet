# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::mariadb_master_ips(String $profile, String $host_prefix) >> Array[Stdlib::IP::Address, 0, 2] {
  $pql = @("PQL")
    resources[certname] {
      type = "Class" and
      title = "${profile}" and
      parameters.is_mariadb_replica = false
      and certname ~ "${host_prefix}"
    }
    | PQL
  $res = wmflib::puppetdb_query($pql)
  if ($res == undef) {
    []
  } else {
    $mariadb_master_certname = $res[0]['certname']
    [ipresolve($mariadb_master_certname, 4), ipresolve($mariadb_master_certname, 6)]
  }
}
