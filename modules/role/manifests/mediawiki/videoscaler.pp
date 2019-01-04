# filtertags: labs-project-deployment-prep
class role::mediawiki::videoscaler {
    system::role { 'mediawiki::videoscaler': }

    include ::role::mediawiki::common

    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::mediawiki::jobrunner
    include ::profile::mediawiki::videoscaler
    include ::profile::base::firewall
    include ::profile::mediawiki::php::monitoring

    # TODO: change role used in beta
    # lint:ignore:wmf_styleguide
    if hiera('has_lvs', true) {
        include ::role::lvs::realserver
        include ::profile::mediawiki::jobrunner_tls
    }
    # lint:endignore
}
