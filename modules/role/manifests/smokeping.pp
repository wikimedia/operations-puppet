# http://oss.oetiker.ch/smokeping/
class role::smokeping {

    system::role { 'smokeping': description => 'smokeping server' }

    include ::profile::smokeping
}
