# SPDX-License-Identifier: Apache-2.0
# == resource scap_source
#
# Sets up scap3 deployment source on a deploy server.
# This will clone $repository at /srv/deployment/$title.
# If $scap_repository is set it will clone it at
# /srv/deployment/$title/scap.  If you set $scap_repository to true,
# this will assume that your scap repository is named $title/scap.
#
# To use this in conjunction with scap::target, make sure the $title here
# matches a scap::target's $title on your target hosts, or at least matches
# the $package_name provided to scap::target (which defaults to $title).
#
# NOTE: This define is compatible with trebuchet's deployment.yaml file.
# If trebuchet has already cloned a source repository in /srv/deployment,
# this clone will do nothing, as it only executes if .git/config
# doesn't already exist.
#
# == Parameters
#
# [*repository*]
#   Repository name in gerrit.  Default: $title
#
# [*scap_repository*]
#   String or boolean.
#
#   If you set this to a string, it will be assumed to be a repository name
#   This scap repository will then be cloned into /srv/deployment/$title/scap.
#   If this is set to true your scap_repository will be assumed to
#   live at $title/scap in gerrit.
#
#   You can use this keep your scap configs separate from your source
#   repositories.
#
#   Default: false.
#
# [*owner*]
#   Owner of cloned repository,
#   Default: trebuchet
#
# [*group*]
#   Group owner of cloned repository.
#   Default: wikidev
#
# [*origin*]
#   VCS to checkout from. Available values are gerrit, phabricator and gitlab
#
#   Default: gerrit
#
# == Usage
#
#   # Clones the 'repo/without/external/scap' repsitory into
#   # /srv/deployment/repo/without/external/scap.
#
#   scap_source { 'repo/without/external/scap': }
#
#
#   # Clones the 'eventlogging' repository into
#   # /srv/deployment/eventlogging/eventbus and
#   # clones the 'eventlogging/eventbus/scap' repository
#   # into /srv/deployment/eventlogging/eventbus/scap
#
#   scap_source { 'eventlogging/eventbus':
#       repository         => 'eventlogging',
#       scap_repository    => true,
#   }
#
#
#   # Clones the 'myproject/myrepo' repository into
#   # /srv/deployment/myproject/myrepo, and
#   # clones the custom scap repository at
#   # 'my/custom/scap/repo' from gerrit into
#   # /srv/deployment/myproject/myrepo/scap
#
#   scap_source { 'myproject/myrepo':
#       scap_repository    => 'my/custom/scap/repo',
#   }
#
Puppet::Type.newtype(:scap_source) do
  @doc = "Puppet type to set up scap repositories on the scap master"

  ensurable do
    desc <<-EOT
If the repository must be set up or not
EOT
    newvalue(:present, :event => :scap_source_created) do
      provider.create
    end

    newvalue(:absent, :event => :scap_source_removed) do
      provider.destroy
    end

    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc "Name of the scap source"
  end

  newparam(:owner) do
    desc "Owner of the cloned repository. Defaults to 'trebuchet'"

    defaultto 'trebuchet'
  end

  newparam(:group) do
    desc "Group owner of the cloned repository. Defaults to 'wikidev'"

    defaultto 'wikidev'
  end

  newproperty(:repository) do
    desc <<-EOT
Repository name in the VCS. Defaults to the resource name
EOT
    defaultto do
      @resource[:name]
    end

    def insync?(is)
      is == should
    end
  end

  newparam(:scap_repository) do
    desc <<-EOT
String or boolean.

If you set this to a string, it will be assumed to be a repository name
This scap repository will then be cloned into /srv/deployment/$title/scap.
If this is set to true your scap_repository will be assumed to
live at $title/scap in gerrit.

You can use this keep your scap configs separate from your source
repositories.
Default: false.
EOT
    defaultto :false
    munge do |value|
      case value
      when false, :false
        false
      when true, :true
        File.join(@resource[:name], 'scap')
      else
        value
      end
    end
  end

  newparam(:origin) do
    desc "The VCS to fetch data from"
    newvalues(:gerrit, :phabricator, :gitlab)
    defaultto :gerrit
  end

  newparam(:base_path) do
    desc "The base path for deploying the repositories"
    defaultto '/srv/deployment'
  end
end
