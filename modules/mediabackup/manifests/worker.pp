# Media backups worker: Install required packages and configures
# them.
# * db_host: fqdn of the database used for the media backups metadata backend
# * db_port: port of such database
# * db_user: user used to authenticate to the database
# * db_password: password used to authenticate to the database
# * db_schema: name of the database inside the server where the data is read
#              from and written to
# * storage_hosts: list of hosts where the file backend runs, where the files
#                  will be finally stored
# * storage_port: Port where all storage nodes will be listening to (it may
#                 change in the future to a per-host configuration (socket)
#                 to allow for multiplexing with multiple services per host
class mediabackup::worker (
    Stdlib::Fqdn        $db_host,
    Stdlib::Port        $db_port,
    String              $db_user,
    String              $db_password,
    Array[Stdlib::Fqdn] $storage_hosts,
    Stdlib::Port        $storage_port,
    String              $db_schema = 'mediabackups',
) {
    ensure_packages(['python3', ])  # placeholder until we have a package
}
