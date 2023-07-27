# SPDX-License-Identifier: Apache-2.0
function ssh::known_hosts (
    Boolean $include_hostnames = true,

) {
    $pql = @("PQL")
    resources[parameters, title] {
        type = 'Sshkey' and exported = true and parameters.ensure = 'present' order by title
    }
    | PQL
    Hash(wmflib::puppetdb_query($pql).map |$resource| {
        $key = $resource['name'].lest || { $resource['title'] }

        if $include_hostnames {
            $params =  $resource['parameters']
        } else {
            $aliases = 'host_aliases' in $resource['parameters'] ? {
                # filter out anything with out dots or colons
                true  => $resource['parameters']['host_aliases'].filter |$alias| { $alias =~ /[\.:]/ },
                false => [],
            }
            $params = $resource['parameters'] + {'host_aliases' => $aliases }
        }
        [$key, $params]
    })
}
