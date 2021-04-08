class profile::parsoid() {
    require ::profile::mediawiki::php
    require ::profile::mediawiki::php::monitoring
    include ::profile::mediawiki::php::restarts
    require ::profile::mediawiki::webserver
}
