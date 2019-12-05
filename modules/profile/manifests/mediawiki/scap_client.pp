# === Class profile::mediawiki::scap_client
# Everything needed to configure a scap2 client for MediaWiki

class profile::mediawiki::scap_client(
    $deployment_server = lookup('scap::deployment_server', Stdlib::Host),
    $wmflabs_master = lookup('scap::wmflabs_master', Optional[Stdlib::Host], 'first', undef),
    $scap_version = lookup('scap::version', String, 'first', 'present'),
    Stdlib::Fqdn $cloud_statsd = lookup('profile::wmcs::monitoring::statsd_master', {default_value => 'cloudmetrics1002.eqiad.wmnet'}),
) {

    # TODO: rewrite the logic around $wmflabs_master
    # TODO: make the admin port a variable across all classes.

    class { '::scap':
        deployment_server => $deployment_server,
        wmflabs_master    => $wmflabs_master,
        version           => $scap_version,
        php7_admin_port   => 9181,
        cloud_statsd_host => $cloud_statsd,
    }

    class { '::mediawiki::scap': }
    class { '::scap::ferm': }
}
