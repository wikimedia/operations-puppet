# definition to clone mediawiki extensions
define mediawiki_singlenode::mw-extension(
	$ensure       = present,
	$branch       = 'master',
	$install_path = '/srv/mediawiki',
) {
	git::clone { $name:
		require   => Git::Clone['mediawiki'],
		directory => "${install_path}/extensions/${name}",
		origin    => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/${name}.git",
		branch    => $branch,
		ensure    => $ensure,
		notify => Exec['mediawiki_update'],
	}
}
