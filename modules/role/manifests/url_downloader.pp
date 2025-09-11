class role::url_downloader {
    include profile::base::production
    include profile::firewall
    include profile::url_downloader

    # Prototype hCaptcha IP blinding proxy is living on url-downloader machines
    # for simplicity. This is behind LVS.
    include profile::lvs::realserver
    include profile::nginx
    include profile::pki::client
    include profile::hcaptcha::proxy
}
