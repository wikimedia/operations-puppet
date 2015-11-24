Puppet::Type.newtype(:etcd_role) do
  @doc = "Puppet type to manage etcd roles."

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the role on etcd"
  end

  newproperty(:acls) do
    desc "Hash of paths and permissions to grant to the user"
    def insync?(is)
      should.each{ |k, v| should[k] = v.upcase }
      is == should
    end
  end

end
