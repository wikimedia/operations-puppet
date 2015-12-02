class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    include ::role::mediawiki::scaler
    include ::mediawiki::jobrunner
    include ::base::firewall
}

