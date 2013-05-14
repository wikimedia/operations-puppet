# application server sudo definitions
class applicationserver::sudo {

	require groups::wikidev

	sudo_group {"wikidev_apache":
		privileges => ['ALL = (apache) NOPASSWD: ALL'],
		group => "wikidev"
	}

	sudo_group {"wikidev_root":
		privileges => ['ALL= NOPASSWD: /usr/sbin/apache2ctl, /etc/init.d/apache2, /usr/bin/renice, /usr/local/bin/find-nearest-rsync'],
		group => "wikidev"
	}

}
