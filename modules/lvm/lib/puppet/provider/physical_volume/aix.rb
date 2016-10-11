Puppet::Type.type(:physical_volume).provide(:iax) do
    desc "Manages LVM physical volumes"
    #defaultof :operatingsystem => AIX
    #confine :operatingsystem => AIX
    
    commands :mkdev  => 'mkdev', :rmdev => 'rmdev', :lspv => 'lspv', :lsvg => 'lsvg'

    def create
        mkdev('-l', @resource[:name])
    end

    def destroy
        rmdev('-l', @resource[:name])
    end

    def exists?
      # If unless_vg is set we need to see if
      # the volume group exists
      if @resource[:unless_vg]
        begin
          # Check to see if the volume group exists
          # if it does set TRUE else FALSE
          lsvg(@resource[:unless_vg])
          vg_exists = true
        rescue Puppet::ExecutionFailure
          vg_exists = false
        end
      end
      # If vg exists FALSE 
      if ! vg_exists
        begin
          # Check to see if the PV already exists
          lspv(@resource[:name])
        rescue Puppet::ExecutionFailure
          false
        end
      else
       # If the VG exists return true
       true
      end
    end

end
