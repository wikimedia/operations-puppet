# old offsite bacula storage host
# to be decommissioned
class role::backup::offsite {
    include profile::base::production
    include profile::backup::storage::oldmain
}
