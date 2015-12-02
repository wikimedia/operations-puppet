class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::role::mediawiki::scaler
    include ::role::mediawiki::webserver
    include ::base::firewall
}


