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

    defaultto do
      if @resource.managed?
        :present
      else
        nil
      end
    end
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

  newparam(:repository) do
    desc <<-EOT
Repository name in the VCS. Defaults to the resource name
EOT
    defaultto do
      @resource[:name]
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
    defaultto false
    munge do |value|
      case value
      when false, :false
        false
      when true, :true
        File.join(@resource[:name],'scap')
      else
        value
      end
    end
  end
end
