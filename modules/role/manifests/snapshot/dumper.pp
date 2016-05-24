# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class role::snapshot::dumper {

    # Allow SSH from deployment hosts
    ferm::rule { 'deployment-ssh':
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    # mw packages and dependencies, dataset server nfs mount
    include snapshot::dumps::packages

    # config, stages files, dblists, html templates
    include snapshot::dumps

    # scap3 deployment of dump scripts
    include dataset::user
    include snapshot::deployment

    # cron job for running the dumps
    include role::snapshot::cron
}
