class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::role::mediawiki::scaler
    include ::role::mediawiki::webserver
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter
    include ::base::firewall
    scap::target: { '3d2png/deploy':
        deploy_user => 'mwdeploy',
    }
}

