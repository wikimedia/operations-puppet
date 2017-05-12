# setup rsyncd and config on the _non_-active phab server
# to allow pushing of /srv/repos from active to passive  (T137928)
class role::phabricator::rsync {

    include rsync::server
    include ::profile::phabricator::rsync
}
