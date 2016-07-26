# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class role::snapshot::dumper {
    include role::snapshot::common

    # cron job for running the dumps
    include role::snapshot::cron

    system::role { 'role::snapshot::dumper':
        description => 'dumper of XML/SQL wiki content',
    }
}
