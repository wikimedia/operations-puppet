# == Class role::restbase
#

@monitoring::group { 'restbase_eqiad': description => 'Restbase eqiad' }
@monitoring::group { 'restbase_codfw': description => 'Restbase codfw' }

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase

    include lvs::realserver


    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}

class role::restbase::alerts {
    monitoring::graphite_threshold { 'restbase_request_5xx_rate':
        description    => 'RESTBase req/s returning 5xx',
        metric         => 'restbase.v1_page_html_-title-_-revision--_tid-.GET.5xx.sample_rate',
        from           => '10min',
        warning        => '1', # 1 5xx/s
        critical       => '3', # 5 5xx/s
        percentage     => '20',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency':
        description    => 'RESTBase HTML storage load mean latency ms',
        metric         => 'movingMedian(restbase.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.mean, 15)',
        from           => '10min',
        warning        => '25', # 25ms
        critical       => '50', # 50ms
        percentage     => '50',
        contact_group  => 'team-services',
    }
}
