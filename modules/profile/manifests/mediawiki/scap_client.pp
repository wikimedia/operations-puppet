# === Class profile::mediawiki::scap_client
# Everything needed to configure a scap2 client for MediaWiki
# @param is_master indicates if the server is a scap::master
class profile::mediawiki::scap_client(
    $deployment_server = lookup('scap::deployment_server', Stdlib::Host),
    $wmflabs_master = lookup('scap::wmflabs_master', Optional[Stdlib::Host], 'first', undef),
    Stdlib::Fqdn $cloud_statsd = lookup('profile::wmcs::monitoring::statsd_master', {default_value => 'cloudmetrics1004.eqiad.wmnet'}),
    Boolean      $is_master    = lookup('profile::mediawiki::scap_client::is_master')
) {

    # TODO: rewrite the logic around $wmflabs_master
    # TODO: make the admin port a variable across all classes.

    class { '::scap':
        deployment_server => $deployment_server,
        wmflabs_master    => $wmflabs_master,
        php7_admin_port   => 9181,
        cloud_statsd_host => $cloud_statsd,
        is_master         => $is_master,
    }

    class { '::mediawiki::scap': }
    class { '::scap::ferm': }
}
