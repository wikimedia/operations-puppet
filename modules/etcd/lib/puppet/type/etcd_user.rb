require 'shellwords'

Puppet::Type.newtype(:etcd_user) do
  @doc = "Puppet type to manage etcd users"

  # TODO: make ensure do the work
  ensurable

  newproperty(:name, :namevar => true) do
    desc "Name of the user on etcd"
  end

  newparam(:password) do
    desc "The password for the etcd user. Will NOT be updated once the user exists,
         unless forcerefresh is set to true"
  end

  newparam(:forcerefresh) do
    desc "Force a refresh of the password"
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:roles, :array_matching => :all) do
    desc "List of roles the user is member of"
  end

  newparam(:params) do
    desc "Command-line arguments needed by etcdctl"
    munge do |value|
      Shellwords.shellsplit(value)
    end
  end


  # TODO: autorequire etcd roles
end
