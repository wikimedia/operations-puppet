class role::mediawiki::imagescaler {
    system::role { 'mediawiki::imagescaler': }

    include ::role::mediawiki::scaler
    include ::role::mediawiki::webserver
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::base::firewall

    # include doesn't allow names to start with numbers
    class { '3d2png::deploy': }
}

