# groups.pp

class groups::search {
	group { 'search':
		ensure    => present,
		gid       => 538,
		alias     => 538,
	}
}

class groups::wikidev {
	group { 'wikidev':
		ensure    => present,
		gid       => 500,
		alias     => 500,
	}
}

class groups::l10nupdate {
	group { 'l10nupdate':
		ensure    => present,
		gid       => 10002,
		alias     => 10002,
	}
}

# group file_mover is used by fundraising
# to move udp2log fundraising logs around.
class groups::file_mover {
	group { 'file_mover':
		ensure    => present,
		gid       => 30001,
		alias     => 30001,
	}
}

class groups::dab {
	group { 'dab':
		ensure    => present,
		gid       => 536,
		alias     => 536,
	}
}
