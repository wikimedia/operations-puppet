class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::role::mediawiki::scaler
    include ::role::mediawiki::webserver
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter
    include ::base::firewall
    include ::3d2png::deploy
}

