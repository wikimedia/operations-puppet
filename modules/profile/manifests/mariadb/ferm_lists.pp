# Firewall rules for the misc db host used by lists.wikimedia.org (Mailman).
# See T256538#6943696, T278614#7023029 for history.
class profile::mariadb::ferm_lists {
    ferm::service { 'mailman3':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(lists1001.wikimedia.org)',
    }
}
