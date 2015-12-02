class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common
    include ::mediawiki::jobrunner
}


