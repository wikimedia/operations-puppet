Puppet::Type.newtype(:etcd_user) do
  @doc = "Puppet type to manage etcd users."

  ensurable do
    desc <<-EOT
      What state the user should be in. If `present`, the user is created
      only if not present (password won't be changed), `absent` will remove it;
      if `force` is used, a password change will be enforced.
    EOT

    newvalue(:present, :event => :etcd_user_created) do
      provider.create
    end

    newvalue(:absent, :event => :etcd_user_removed) do
      provider.destroy
    end

    newvalue(:force) do
      if provider.exists?
        provider.refresh_password
      else
        provider.create
      end
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
    desc "Name of the user on etcd"
  end

  newparam(:password) do
    desc "The password for the etcd user. Will NOT be updated once the user exists,
         unless forcerefresh is set to true"
  end

  newproperty(:roles, :array_matching => :all) do
    desc "List of roles the user is member of"
    def insync?(is)
      is.sort == should.sort
    end
  end

  # TODO: autorequire etcd roles
end
