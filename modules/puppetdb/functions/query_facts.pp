# SPDX-License-Identifier: Apache-2.0
# @summery query for custome facts for a host and return a hash of facts values keyed to the certname
# @param filter a hash of fact name to fetch
# @param a pql subquery to apply to the query
function puppetdb::query_facts(
    Array[String[1]]    $filter,
    Optional[String[1]] $subquery = undef,
) >> Hash[Stdlib::Fqdn, Hash] {
    $_subquery = $subquery ? {
        undef   => '',
        default => " and ${subquery}"
    }
    $filter_str = $filter.map |$filter| { "\"${filter}\"" }.join(',')
    $pql = "facts[certname, name, value] { name in [${filter_str}] ${_subquery} }"
    puppetdb::munge_facts(puppetdb_query($pql))
}
