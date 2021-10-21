# MediaWiki events to IRC (irc.wikimedia.org)
#
class role::mediawiki::irc_events {
    system::role { 'mediawiki::irc_events': }
    include ::profile::base::production
    include ::profile::base::firewall
}
