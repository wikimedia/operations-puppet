# SPDX-License-Identifier: Apache-2.0
# @summery query for facts for a host and return a hash of facts values
#          keyed to their hostname
# @param filter a hash of facts to fetch
# @param a pql subquery to apply to the query
function puppetdb::query_facts(
    Array[String[1]]    $filter,
    Optional[String[1]] $subquery = undef,
) >> Hash[Stdlib::Fqdn, Hash] {
    $pql = "inventory[certname, ${filter.join(',')}] { ${subquery} }"
    puppetdb::munge_facts(wmflib::puppetdb_query($pql))
}
