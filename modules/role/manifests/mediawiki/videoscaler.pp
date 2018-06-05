class role::mediawiki::videoscaler {
    system::role { 'mediawiki::videoscaler::lvs': }
    include ::role::mediawiki::videoscaler_base
    include ::role::lvs::realserver
    include ::profile::mediawiki::jobrunner_tls
}
