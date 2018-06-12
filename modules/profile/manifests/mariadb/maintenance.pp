# maintenance needed on maintenance hosts for mediawiki databases
class profile::mariadb::maintenance(
    $ensure = hiera('profile::mariadb::maintenance::ensure'),
    ) {
    # The role should install profile::mariadb::client

    # TODO: MySQL maintenance will go here (e.g. statistics
    # gathering, schema consistencing checking, etc.). Those
    # will happen but they are still in development (it should
    # be mostly cron jobs running scripts).
}
