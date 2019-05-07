# === Class profile::mediawiki::scap_client
# Everything needed to configure a scap2 client for MediaWiki

class profile::mediawiki::scap_client(
    $deployment_server = lookup('scap::deployment_server', Stdlib::Host),
    $wmflabs_master = lookup('scap::wmflabs_master', Optional[Stdlib::Host], 'first', undef),
    $scap_version = lookup('scap::version', String, 'first', 'present'),
) {

    # TODO: rewrite the logic around $wmflabs_master
    # TODO: make the admin port a variable across all classes.

    class { '::scap':
        deployment_server => $deployment_server,
        wmflabs_master    => $wmflabs_master,
        version           => $scap_version,
        php7_admin_port   => 9181,
    }

    class { '::mediawiki::scap': }
    class { '::scap::ferm': }
}
