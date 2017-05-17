# this class is for snapshot test hosts which should
# have all software and configuration needed to
# generate sql/xml dumps without automatically running
# them
class role::snapshot::testbed {
    include role::snapshot::common

    system::role { 'snapshot::testbed':
        description => 'testbed for dumps of XML/SQL wiki content',
    }
}
