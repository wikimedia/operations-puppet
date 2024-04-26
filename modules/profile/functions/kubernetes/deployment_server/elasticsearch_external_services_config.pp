# SPDX-License-Identifier: Apache-2.0
function profile::kubernetes::deployment_server::elasticsearch_external_services_config(String $role, Array[String] $datacenters) {
  $datacenters.map |$datacenter| {
    # We fetch every hostname with the argument role, in the current datacenter, ordered by hostname
    $hostnames_in_role_and_dc_pql = @("PQL")
    nodes[certname] {
      resources {
        type = 'Class' and
        title = 'Role::Elasticsearch::${role.capitalize}' and
        certname ~ '${datacenter}.wmnet'
      }
      order by certname
    }
    | PQL
    $es_hosts = wmflib::puppetdb_query($hostnames_in_role_and_dc_pql)

    # We store a hostname -> [ipv4, ipv6] mapping
    $es_hosts_to_ips = Hash(
      $es_hosts.map |$data| {
        [
          $data['certname'],
          [ipresolve($data['certname']), ipresolve($data['certname'], 6)]
        ]
      }
    )

    # We query the ES profile parameters, to see how it was configured
    $es_config_pql =  @("PQL")
    resources[parameters] {
      type = 'Class' and
      title = 'Profile::Elasticsearch' and
      certname = '${es_hosts[0]['certname']}'
    }
    | PQL
    $es_config = wmflib::puppetdb_query($es_config_pql)[0]

    # For each ES cluster in the profile, we return an external service data structure, containing
    # the http and tls ports, as well as a single instance, containing the ipv4/6 of each associated host.
    Hash(
      $es_config['parameters']['instances'].map |$es_instance_name, $es_instance| {
        $es_cluster_hosts = $es_instance['cluster_hosts'].lest || { $es_config['parameters']['dc_settings']['cluster_hosts'] }
        [
          "elasticsearch-${es_instance_name}",  # this already contains the datacenter name
          {
            '_meta' => {
              'ports' => [
                {
                  'name' => 'tls',
                  'port' => Stdlib::Port($es_instance['tls_port']),
                },
                {
                  'name' => 'http',
                  'port' => Stdlib::Port($es_instance['http_port']),
                },
              ],
            },
            'instances' => {
              downcase($role) => $es_cluster_hosts.reduce([]) |$map, $es_hostname| {
                $map + $es_hosts_to_ips[$es_hostname]
              }.filter |$ip| { $ip != undef },
            }
          }
        ]
      }
    )
  }.reduce({}) |$mem, $val| { $mem.merge($val) }
}
