# read-only IRC server to display RecentChanges
class role::ircserver {

    system::role { 'role::ircserver': description => 'MW Changes IRC Broadcast Server' }

    include ::standard
    include ::profile::ircserver::charybdis

}
