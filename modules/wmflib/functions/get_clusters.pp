# SPDX-License-Identifier: Apache-2.0
function wmflib::get_clusters (
    Wmflib::Selector $selector = {}
) {

    $clusters = $selector['cluster'].lest || { lookup('wikimedia_clusters').keys() }
    $sites = $selector['site'].lest || { [] }
    $pql = @("PQL")
    resources[certname, parameters] {
        type = "Class" and title = "Cumin::Selector"
        order by parameters
    }
    | PQL
    $data = wmflib::puppetdb_query($pql)
    # Note: I tried to do the filtering on with pql however using:
    #   parameters.cluster in ["foo"] cause a syntax error
    # I then tried to build a massive or statement e.g.
    #  (parameter.cluster = "misc" or parameter.cluster = "foo" or ...)
    # however this cause puppetdb to OOM and die :/
    $data.filter |$item| {
        $item['parameters']['cluster'] in $clusters and
        ($sites.empty() or $item['parameters']['site'] in $sites)
    }.merge |$hsh, $item| {
        $cluster = $item['parameters']['cluster']
        $site = $item['parameters']['site']
        $value = $hsh.dig($cluster, $site).lest || { [] } << $item['certname']
        $result = { $cluster => { $site => $value.sort } }
        deep_merge($hsh, $result)
    }
}
