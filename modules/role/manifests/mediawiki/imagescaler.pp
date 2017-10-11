class role::mediawiki::imagescaler {
    system::role { 'mediawiki::imagescaler': }

    include ::role::mediawiki::scaler
    include ::role::mediawiki::webserver
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::base::firewall
    include ::threedtopng::deploy
}
