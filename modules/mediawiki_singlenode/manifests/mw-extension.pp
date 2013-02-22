# definition to clone mediawiki extensions
define mw-extension(
	# defaults
	$branch="master",
	$ssh="",
	$owner="root",
	$group="root",
	$timeout="300",
	$depth="full",
	$mode=0755) {
	git::clone { "$name":
		require => git::clone["mediawiki"],
		directory => "${install_path}/extensions/${name}",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/${name}.git",
		branch => $branch,
		ensure => $ensure,
	}
}
