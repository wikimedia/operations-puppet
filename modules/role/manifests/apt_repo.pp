# Sets up a webserver (nginx) and an APT repository.
class role::apt_repo {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::base::cuminunpriv

    include profile::nginx
    include profile::installserver::http
    include profile::installserver::preseed
    include profile::installserver::efiboot
    include profile::aptrepo::wikimedia
    include profile::opensearch::plugin_repo
}
