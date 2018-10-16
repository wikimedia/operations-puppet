# filtertags: labs-project-deployment-prep
class role::mediawiki::appserver {
    system::role { 'mediawiki::appserver': }
    include standard
    include ::role::mediawiki::common

    # Temporary to test the new profile
    if $::hostname =~ /^mwdebug\d+/ or $::realm == 'labs' {
        include ::profile::mediawiki::webserver
    }
    else {
        include ::role::mediawiki::webserver
    }
    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
}
