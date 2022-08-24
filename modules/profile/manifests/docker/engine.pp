# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine(
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hash merge behavior to merge keys across the hierarchy
    Hash $settings = lookup('profile::docker::engine::settings', { 'default_value' => {}} ),
    # Version to install; the default is not to pick one.
    # NOTE: this must be set on OS < buster.
    Optional[String] $version = lookup('profile::docker::engine::version', { 'default_value' => undef }),
    # Override the default docker engine package name.  See docker/init.pp for
    # default names on different Debian OS versions.
    Optional[String] $packagename = lookup('profile::docker::engine::packagename', { 'default_value' => undef }),
    # Set to false if we don't want to declare the docker service here
    # We want this to be on if we want to use a different docker systemd service (with flannel support, for eg.)
    Boolean $declare_service = lookup('profile::docker::engine::declare_service', { 'default_value' => true }),
) {

    if debian::codename::le('buster') {
        # See https://docs.docker.com/engine/install/linux-postinstall/#your-kernel-does-not-support-cgroup-swap-limit-capabilities
        # This seems not needed on Bullseye since Docker is provided.
        require ::profile::base::memory_cgroup
    }

    # On Buster and later we use Docker from Debian
    if debian::codename::lt('buster') {
        apt::repository { 'thirdparty-k8s':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/k8s',
            before     => Class['docker'],
        }
    }

    # Docker config
    # This will pick the storage setup that is default with docker, which
    # on servers >= buster means overlay2 if available, else the devicemapper-on-disk
    # driver that is highly discouraged
    if (defined(Class['profile::base']) and $profile::base::overlayfs == false) {
        warning('Using the default configuration of docker without enabling overlayfs, this is discouraged. Please ensure you declare profile::base::overlayfs: true in hiera.')
    }

    class { 'docker::configuration':
        settings => $settings,
    }

    # Install docker, we should remove the "version" parameter when everything
    # is using Buster/Docker as packaged by Debian.
    class { 'docker':
        version      => $version,
        package_name => $packagename,
    }

    if $declare_service {
        # Service declaration
        service { 'docker':
            ensure => 'running',
        }
    }
}
