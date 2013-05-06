# == Class: bugzilla::modifications
#
# Installs Wikimedia-specific patches and extensions for Bugzilla. The
# patches are fetched from a dedicated Git repository
# (wikimedia/bugzilla/modifications), applied on top of the Bazaar
# checkout of Bugzilla, and committed to Bazaar.
#
class bugzilla::modifications {
	git::clone { 'wikimedia/bugzilla/modifications':
		ensure    => present,
		directory => "${bugzilla::dir}/modifications",
		origin    => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/modifications.git',
		branch    => 'master',
	}

	# Copy Wikimedia-specific modifications to the Bugzilla tree.
	exec { 'apply modifications':
		command     => "rsync -r ${bugzilla::dir}/modifications/bugzilla-${bugzilla::series}/ ${bugzilla::install_dir}",
		creates     => "${bugzilla::install_dir}/extensions/Wikimedia/",
		notify      => Exec['commit modifications'],
		path        => '/usr/bin',
		refreshonly => true,
		require     => Exec['bzr checkout'],
	}

	# Create a local Bazaar commit of Wikimedia modifications and label
	# it with the SHA1 of wikimedia/bugzilla/modifications's tip.
	$ref = "${bugzilla::dir}/modifications/.git/refs/heads/master"
	exec { 'commit modifications':
		command     => "bzr add && bzr commit --local --file=${ref}",
		unless      => "bzr log -l1 | grep -f ${ref}",
		cwd         => $bugzilla::install_dir,
		path        => [ '/bin', '/usr/bin' ],
		refreshonly => true,
	}
}
