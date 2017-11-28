# filtertags: labs-project-deployment-prep labs-project-ircd
class role::mw_rc_irc {

    system::role { 'mw_rc_irc': description => 'MW Changes IRC Broadcast Server' }

    include ::standard
    include ::profile::base::firewall
    include ::passwords::udpmxircecho
    include ::profile::mw_rc_irc

}
