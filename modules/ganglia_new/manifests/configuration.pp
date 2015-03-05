# modules/ganglia/manifests/configuration.pp

class ganglia_new::configuration {
    # NOTE: Do *not* add new clusters *per site* anymore,
    # the site name will automatically be appended now,
    # and a different IP prefix will be used.
    $clusters = {
        'decommissioned'=> {
            'name'      => 'Decommissioned servers',
            'id'    => 1,
            'sites' => ['eqiad', 'esams'] },
        'lvs'   => {
            'name'      => 'LVS loadbalancers',
            'id'    => 2,
            'sites' => ['eqiad', 'esams', 'codfw']  },
        'search'    =>  {
            'name'      => 'Search',
            'id'    => 4 },
        'mysql'     =>  {
            'name'      => 'MySQL',
            'id'    => 5 },
        'misc'      =>  {
            'name'      => 'Miscellaneous',
            'id'    => 8,
            'sites' => ['eqiad', 'esams', 'codfw'] },
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
            'sites' => ['codfw', 'eqiad', 'esams']  },
        'cache_mobile'  => {
            'name'      => 'Mobile caches',
            'id'    => 28,
            'sites' => ['eqiad', 'esams'] },
        'virt'  => {
            'name'      => 'Virtualization cluster',
            'id'    => 29 },
        'jobrunner' =>  {
            'name'  => 'Jobrunners',
            'id'    => 31,
            'sites' => ['eqiad', 'codfw'] },
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
        'ceph'          => { # Not used anymore
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
        'elasticsearch' => {
            'name'      => 'Elasticsearch cluster',
            'id'    => '42' },
        'logstash'      => {
            'name'      => 'Logstash cluster',
            'id'    => '43' },
        'rcstream'      => {
            'name'      => 'RCStream cluster',
            'id'    => '44' },
        'analytics_kafka' => {
            'name'      => 'Analytics Kafka cluster',
            'id'    => '45' },
        'sca'           => {
            'name'      => 'Service Cluster A',
            'id'    => '46' },
        'openldap_corp_mirror'           => {
            'name'      => 'Corp OIT LDAP mirror',
            'id'    => '47' },
    }
    # NOTE: Do *not* add new clusters *per site* anymore,
    # the site name will automatically be appended now,
    # and a different IP prefix will be used.

    $url = 'http://ganglia.wikimedia.org'
    # 208.80.154.14 is neon (icinga).
    # It is not actually a gmetad host, but it should
    # be allowed to query gmond instances for use by
    # neon/icinga.
    $gmetad_hosts = [ '208.80.154.53', '208.80.154.150', '208.80.154.14' ]
    $aggregator_hosts = {
        'eqiad' => [ '208.80.154.53', '208.80.154.150' ],
        'esams' => [ '91.198.174.113' ],
        'codfw' => [ '208.80.153.4' ],
    }
    $base_port = 8649
    $id_prefix = {
        eqiad => 1000,
        codfw => 2000,
        esams => 3000,
    }
    $default_sites = ['eqiad','codfw']
}
