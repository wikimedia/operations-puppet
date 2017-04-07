# filtertags: labs-project-deployment-prep labs-project-ircd
class role::mw_rc_irc {

    system::role { 'role::mw_rc_irc': description => 'MW Changes IRC Broadcast Server' }

    include ::standard
    include ::base::firewall
    include ::passwords::udpmxircecho
    include ::mw_rc_irc::ircserver
    include ::profile::mw_rc_irc

}
