# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class role::snapshot::dumper {

    # set up scap3 deployment of dump scripts except for
    # all the misc cron jobs (not handled in this class)
    include dataset::user
    include snapshot::deployment
}
