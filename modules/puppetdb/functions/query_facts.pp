# @summery query for custome facts for a host and return a hash of facts values keyed to the certname
# @param filter a hash of fact name to fetch
# @param a pql subquery to apply to the query
function puppetdb::query_facts(
    Array[String[1]]    $filter,
    Optional[String[1]] $subquery = undef,
) {
#) >> Hash[Stdlib::Fqdn, Hash[String[1], String[1]]] {
    $_subquery = $subquery ? {
        undef   => '',
        default => " and ${subquery}"
    }
    $filter_str = $filter.map |$filter| { "\"${filter}\"" }.join(',')
    $pql = "facts[certname, name, value] { name in [${filter_str}] ${_subquery} }"
    puppetdb_query($pql).reduce( {}) |$memo, $value| {
        deep_merge($memo, {$value['certname'] => { $value['name'] => $value['value']}})
    }
}
