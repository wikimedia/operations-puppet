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
          if @resource.parameter(:followsymlinks).value == :true then
            real_should = []
            real_is = []
            should.each do |s|
              if File.symlink?(s)
                device = File.expand_path(File.readlink(s), File.dirname(s))
                debug("resolved symlink '"+s+"' to device '"+ device+"'")
                real_should.push device
              else
                real_should.push s
              end
            end
            is.each do |s|
              if File.symlink?(s)
                device = File.expand_path(File.readlink(s), File.dirname(s))
                debug("resolved symlink '"+s+"' to device '"+ device+"'")
                real_is.push device
              else
                real_is.push s
              end
            end

            real_should.sort == real_is.sort
          else
            should.sort == is.sort
          end
        end
    end

    newparam(:followsymlinks, :boolean => true) do
      desc "If set to true all current and wanted values of the physical_volumes property
        will be followed to their real files on disk if they are in fact symlinks. This is
        useful to have Puppet determine what the actual PV device is if the property value
        is a symlink, like '/dev/disk/by-path/xxxx -> ../../sda'. Defaults to `False`."
      newvalues(:true, :false)
      aliasvalue(:yes, :true)
      aliasvalue(:no, :false)
      defaultto :false
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
