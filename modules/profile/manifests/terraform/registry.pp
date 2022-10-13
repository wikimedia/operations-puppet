# SPDX-License-Identifier: Apache-2.0
# @summary Server to host terraform.wmcloud.org/registry
# @param $uploader_group Unix group of users who can upload new files
class profile::terraform::registry (
  String $uploader_group = lookup('profile::terraform::registry::uploader_group', {default_value => 'root'}),
) {
  class { 'httpd':
    modules => ['proxy', 'proxy_uwsgi'],
  }

  httpd::site { 'terraform.wmcloud.org':
    content => template('profile/terraform/registry/vhost.conf.erb'),
  }

  ensure_packages(['python3-flask'])

  file { '/usr/local/bin/tf-registry-uwsgi.py':
    source => 'puppet:///modules/profile/terraform/registry/tf-registry-uwsgi.py',
    mode   => '0555',
  }

  uwsgi::app { 'tf-registry':
    settings  => {
      uwsgi => {
        plugins            => 'python3',
        master             => true,
        socket             => '/run/uwsgi/tf-registry.sock',
        mount              => '/tf-registry=/usr/local/bin/tf-registry-uwsgi.py',
        callable           => 'app',
        manage-script-name => true,
        workers            => 4,
      },
    },
    subscribe => File['/usr/local/bin/tf-registry-uwsgi.py'],
  }

  wmflib::dir::mkdir_p([
    '/srv/terraform-registry/config',
    '/srv/terraform-registry/config/providers',
    '/srv/terraform-registry/files',
  ], {
    owner => 'root',
    group => $uploader_group,
    # enable setgid to ensure people can edit the config files created by others
    mode  => '2775',
  })
}
