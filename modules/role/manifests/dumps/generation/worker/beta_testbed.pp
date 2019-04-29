# == Class role::dumps::generation::worker::beta_testbed
#
# Set up a dumps snapshot instance as a testbed.
#
# Because this class uses mediawiki, the class
# role::beta::mediawiki must be applied to the instance
# as well.  The role can't be included in this class for
# style reasons.
#
# You should be using at least a m1.medium instance,
# giving some extra lvm space locally mounted on
# which to write the dumps.
#
# filtertags: labs-project-deployment-prep
class role::dumps::generation::worker::beta_testbed {
    include ::profile::standard

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::crontester

    system::role { 'dumps::generation::worker::beta_testbed':
        description => 'beta testbed for dumps of XML/SQL wiki content',
    }
}
