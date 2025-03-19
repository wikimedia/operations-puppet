# SPDX-License-Identifier: Apache-2.0
# Liberica DNS healthcheck configuration
# [*type*]
#  String used by liberica to identify DNS healthchecks.
#  It must be set to DNSCheck
# [*query_type*]
#  DNS query type to perform. Only A supported at this time
#  the host part of the URL
# [*domain_name*]
#  Domain name that needs to be queried (www.wikipedia.org,
#  upload.wikimedia.org.)
# [*timeout*]
#  timeout to perform the DNS query (5s, 5000ms)
# [*check_period*]
#  time between checks (3s, 3000ms)
type Liberica::DNSCheck = Struct[{
        'type'         => Enum['DNSCheck'],
        'query_type'   => Enum['A'],
        'domain_name'  => Stdlib::Fqdn,
        'timeout'      => String[2],
        'check_period' => String[2],
}]
