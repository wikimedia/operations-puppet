# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::mariadb_master_ips(String $profile, String $host_prefix) >> Array[Stdlib::IP::Address, 2, 2] {
  $pql = @("PQL")
    resources[certname] {
      type = "Class" and
      title = "${profile}" and
      parameters.is_mariadb_replica = false
      and certname ~ "${host_prefix}"
    }
    | PQL
  $mariadb_master_certname = wmflib::puppetdb_query($pql)[0]['certname']
  [ipresolve($mariadb_master_certname, 4), ipresolve($mariadb_master_certname, 6)]
}
