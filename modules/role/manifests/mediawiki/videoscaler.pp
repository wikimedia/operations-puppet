class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    include ::role::mediawiki::scaler
    include ::mediawiki::jobrunner
    include ::base::firewall

    ferm::service { 'mediawiki-jobrunner-videoscalers':
        proto   => 'tcp',
        port    => $::mediawiki::jobrunner::port,
        notrack => true,
        srange  => '$INTERNAL',
    }
}

