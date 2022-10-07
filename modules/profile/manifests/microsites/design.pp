# SPDX-License-Identifier: Apache-2.0
# https://design.wikimedia.org (T185282)
class profile::microsites::design(
  Stdlib::Fqdn $server_name = lookup('profile::microsites::design::server_name'),
  String $server_admin = lookup('profile::microsites::design::server_admin'),
) {

    httpd::site { 'design.wikimedia.org':
        content => template('profile/design/design.wikimedia.org-httpd.erb'),
    }

    $design_blog_repo_dir = '/srv/org/wikimedia/design-blog'
    $design_blog_docroot  = "${design_blog_repo_dir}/_site"

    wmflib::dir::mkdir_p($design_blog_repo_dir)
    wmflib::dir::mkdir_p('/srv/org/wikimedia/design')
    wmflib::dir::mkdir_p('/srv/org/wikimedia/design-strategy')

    git::clone { 'design/landing-page':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/design',
        branch    => 'master',
    }

    git::clone { 'design/strategy':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/design-strategy',
        branch    => 'master',
    }

    git::clone { 'design/blog':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => $design_blog_repo_dir,
        branch    => 'master',
    }

    scap::target { 'design/style-guide':
        deploy_user => 'deploy-design',
    }

    file { '/srv/org/wikimedia/design-style-guide':
        ensure  => 'link',
        target  => '/srv/deployment/design/style-guide',
        require => Scap::Target['design/style-guide'],
    }
}
