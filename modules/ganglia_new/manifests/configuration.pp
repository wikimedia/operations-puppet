# modules/ganglia/manifests/configuration.pp

class ganglia_new::configuration {
    # NOTE: Do *not* add new clusters *per site* anymore,
    # the site name will automatically be appended now,
    # and a different IP prefix will be used.
    $clusters = {
        'decommissioned'=> {
            'name'      => 'Decommissioned servers',
            'id'    => 1,
            'sites' => ['pmtpa', 'eqiad', 'esams'] },
        'lvs'   => {
            'name'      => 'LVS loadbalancers',
            'id'    => 2,
            'sites' => ['pmtpa', 'eqiad', 'esams']  },
        'search'    =>  {
            'name'      => 'Search',
            'id'    => 4 },
        'mysql'     =>  {
            'name'      => 'MySQL',
            'id'    => 5 },
        'misc'      =>  {
            'name'      => 'Miscellaneous',
            'id'    => 8,
            'sites' => ['pmtpa', 'eqiad', 'esams'] },
        'appserver' =>  {
            'name'      => 'Application servers',
            'id'    => 11   },
        'imagescaler'   =>  {
            'name'      => 'Image scalers',
            'id'    => 12 },
        'api_appserver' =>  {
            'name'      => 'API application servers',
            'id'    => 13 },
        'pdf'           =>  {
            'name'      => 'PDF servers',
            'id'    => 15 },
        'cache_text'    => {
            'name'      => 'Text caches',
            'id'    => 20,
            'sites' => ['eqiad', 'esams'] },
        'cache_bits'    => {
            'name'      => 'Bits caches',
            'id'    => 21,
            'sites' => ['eqiad', 'esams'] },
        'cache_upload'  => {
            'name'      => 'Upload caches',
            'id'    => 22,
            'sites' => ['eqiad', 'esams'] },
        'payments'  => {
            'name'      => 'Fundraiser payments',
            'id'    => 23 },
        'ssl'       => {
            'name'      => 'SSL cluster',
            'id'    => 26,
            'sites' => ['eqiad', 'esams'] },
        'swift' => {
            'name'      => 'Swift',
            'id'    => 27,
            'sites' => ['pmtpa', 'eqiad', 'esams']  },
        'cache_mobile'  => {
            'name'      => 'Mobile caches',
            'id'    => 28,
            'sites' => ['eqiad', 'esams'] },
        'virt'  => {
            'name'      => 'Virtualization cluster',
            'id'    => 29 },
        'gluster'   => {
            'name'      => 'Glusterfs cluster',
            'id'    => 30 },
        'jobrunner' =>  {
            'name'      => 'Jobrunners',
            'id'    => 31 },
        'analytics'     => {
            'name'      => 'Analytics cluster',
            'id'    => 32 },
        'memcached'     => {
            'name'      => 'Memcached',
            'id'    => 33 },
        'videoscaler'   => {
            'name'      => 'Video scalers',
            'id'    => 34 },
        'fundraising'   => {
            'name'      => 'Fundraising',
            'id'    => 35 },
        'ceph'          => {
            'name'      => 'Ceph',
            'id'    => 36 },
        'parsoid'       => {
            'name'      => 'Parsoid',
            'id'    => 37 },
        'cache_parsoid' => {
            'name'      => 'Parsoid Varnish',
            'id'    => 38 },
        'redis'         => {
            'name'      => 'Redis',
            'id'    => 39 },
        'labsnfs'   => {
            'name'      => 'Labs NFS cluster',
            'id'    => 40 },
        'cache_misc'    => {
            'name'      => 'Misc Web caching cluster',
            'id'    => 41 },
    }
    # NOTE: Do *not* add new clusters *per site* anymore,
    # the site name will automatically be appended now,
    # and a different IP prefix will be used.

    case $::realm {
        'production': {
            $url = 'http://ganglia.wikimedia.org'
            # 208.80.154.14 is neon (icinga).
            # It is not actually a gmetad host, but it should
            # be allowed to query gmond instances for use by
            # ganglios.
            $gmetad_hosts = [ '208.80.152.15', '208.80.154.150', '208.80.154.14' ]
            $aggregator_hosts = {
                'pmtpa' => [ '208.80.152.15', '208.80.154.150' ],
                'eqiad' => [ '208.80.152.15', '208.80.154.150' ],
                'esams' => [ '91.198.174.113' ]
            }
            $base_port = 8649
            $id_prefix = {
                pmtpa => 0,
                eqiad => 1000,
                esams => 3000,
            }
            $default_sites = ['pmtpa', 'eqiad']
        }
        'labs': {
            $url = 'http://ganglia.wmflabs.org'
            $gmetad_hosts = [ '10.68.16.101']   # aggregator.eqiad.wmflabs
            $aggregator_hosts = {
                'pmtpa' => [ '10.4.0.79' ],     # aggregator1.pmtpa.wmflabs
                'eqiad' => [ '10.68.16.101' ],  # aggregator.eqiad.wmflabs
            }
            $base_port = 8649
            $id_prefix = {
                pmtpa => 0,
                eqiad => 0,
            }
            $default_sites = ['pmtpa', 'eqiad']
        }
    }
}
