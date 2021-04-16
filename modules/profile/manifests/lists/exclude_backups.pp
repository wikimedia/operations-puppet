# dummy class that only contains a variable defining a list of paths to skip
# on backup, for use when defining the mailman 2 backup dataset
class profile::lists::exclude_backups(
    Array[String] $exclude_lists = lookup('mailman2_exclude_backups'),
) {
    $exclude_backups_list = $exclude_lists.map |String $list| {
            "/var/lib/mailman/archives/private/${list}/attachments"
    }
}
