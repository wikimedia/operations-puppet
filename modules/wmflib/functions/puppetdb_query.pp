# SPDX-License-Identifier: Apache-2.0
function wmflib::puppetdb_query (
    String[1] $query,
) >> Array[Hash] {
    if wmflib::have_puppetdb() {
        puppetdb_query($query)
    } else {
        warning('puppetdb_query function not usable, returning an empty array')
        Array({})
    }
}
