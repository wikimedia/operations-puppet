# https://gitlab.wikimedia.org/
# https://phabricator.wikimedia.org/project/view/5057/
class role::gitlab {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::gitlab
}
