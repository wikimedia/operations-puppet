Puppet::Type.newtype(:volume_group) do
    ensurable

    newparam(:name) do
        desc "The name of the volume group."
        isnamevar
    end

    newproperty(:physical_volumes, :array_matching => :all) do
        desc "The list of physical volumes to be included in the volume group; this
             will automatically set these as dependencies, but they must be defined elsewhere
             using the physical_volume resource type."

        def insync?(is)
          should.sort == is.sort
        end
    end

    newparam(:createonly, :boolean => true) do
      desc "If set to true the volume group will be created if it does not exist. If the
        volume group does exist no action will be taken. Defaults to `false`."
      newvalues(:true, :false)
      aliasvalue(:yes, :true)
      aliasvalue(:no, :false)
      defaultto :false
    end

end
