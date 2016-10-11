Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvremove => 'pvremove', :pvs => 'pvs', :vgs => 'vgs'

    def self.instances
      get_physical_volumes.collect do |physical_volumes_line|
        physical_volumes_properties = get_physical_volume_properties(physical_volumes_line)
        new(physical_volumes_properties)
      end
    end

    def create
      create_physical_volume(@resource[:name])
    end

    def destroy
      pvremove(@resource[:name])
    end

    def exists?
      # If unless_vg is set we need to see if
      # the volume group exists
      if @resource[:unless_vg]
        begin
          # Check to see if the volume group exists
          # if it does set TRUE else FALSE
          vgs(@resource[:unless_vg])
          vg_exists = true
        rescue Puppet::ExecutionFailure
          vg_exists = false
        end
      end
      # If vg exists FALSE 
      if ! vg_exists
        begin
          # Check to see if the PV already exists
          pvs(@resource[:name])
        rescue Puppet::ExecutionFailure
          false
        end
      else
       # If the VG exists return true
       true
      end
    end

    def self.get_physical_volumes
      full_pvs_output = pvs.split("\n")

      # Remove first line
      physical_volumes = full_pvs_output.drop(1)

      physical_volumes
    end

    def self.get_physical_volume_properties(physical_volumes_line)
      physical_volumes_properties = {}

      # pvs output formats thus:
      # PV         VG       Fmt  Attr PSize  PFree

      # Split on spaces
      output_array = physical_volumes_line.gsub(/\s+/m, ' ').strip.split(" ")

      # Assign properties based on headers
      # Just doing name for now...
      physical_volumes_properties[:ensure]     = :present
      physical_volumes_properties[:name]       = output_array[0]

      physical_volumes_properties
    end

    private

    def create_physical_volume(path)
      args = []
      if @resource[:force] == :true
        args.push('--force')
      end
      args << path
        pvcreate(*args)
    end

end
