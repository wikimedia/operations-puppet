class role::mediawiki::jobrunner {
    system::role { 'mediawiki::jobrunner::lvs': }
    include ::role::mediawiki::jobrunner_base
    include ::role::lvs::realserver
    include ::profile::mediawiki::jobrunner_tls
}
