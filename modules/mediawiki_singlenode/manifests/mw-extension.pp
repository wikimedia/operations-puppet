# definition to clone mediawiki extensions
define mw-extension(
	# defaults
	$branch="master",
	$ensure=present,
	$install_path="/srv/mediawiki") {
	git::clone { "$name":
		require => git::clone["mediawiki"],
		directory => "${install_path}/extensions/${name}",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/${name}.git",
		branch => $branch,
		ensure => $ensure,
	}
}
