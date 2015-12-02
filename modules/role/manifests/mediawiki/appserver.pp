class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    include ::role::mediawiki::webserver

}

