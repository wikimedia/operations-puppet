# runners for https://gitlab.wikimedia.org/
# https://phabricator.wikimedia.org/project/view/5555/
class role::gitlab_runner {
    include profile::base::production
    include profile::firewall
    include profile::gitlab::runner
}
