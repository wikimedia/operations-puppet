# application server sudo definitions
class applicationserver::sudo {

	require groups::wikidev

	sudo_group {"wikidev": privileges => ['ALL = (apache) NOPASSWD: ALL'] }

	sudo_group {"wikidev": privileges => ['ALL= NOPASSWD: /usr/sbin/apache2ctl, /etc/init.d/apache2, /usr/bin/renice'] }

}