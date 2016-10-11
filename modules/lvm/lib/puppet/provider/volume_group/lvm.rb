Puppet::Type.type(:volume_group).provide :lvm do
    desc "Manages LVM volume groups"

    commands :vgcreate => 'vgcreate',
             :vgremove => 'vgremove',
             :vgs      => 'vgs',
             :vgextend => 'vgextend',
             :vgreduce => 'vgreduce',
             :pvs      => 'pvs'

    def self.instances
      get_volume_groups.collect do |volume_groups_line|
        volume_groups_properties = get_logical_volume_properties(volume_groups_line)
        new(volume_groups_properties)
      end
    end

    def self.get_volume_groups
      full_vgs_output = vgs.split("\n")

      # Remove first line
      volume_groups = full_vgs_output.drop(1)

      volume_groups
    end

    def self.get_logical_volume_properties(volume_groups_line)
      volume_groups_properties = {}

      # vgs output formats thus:
      # VG       #PV #LV #SN Attr   VSize  VFree

      # Split on spaces
      output_array = volume_groups_line.gsub(/\s+/m, ' ').strip.split(" ")

      # Assign properties based on headers
      # Just doing name for now...
      volume_groups_properties[:ensure]     = :present
      volume_groups_properties[:name]       = output_array[0]

      volume_groups_properties
    end

    def create
        vgcreate(@resource[:name], *@resource.should(:physical_volumes))
    end

    def destroy
        vgremove(@resource[:name])
    end

    def exists?
        vgs(@resource[:name])
    rescue Puppet::ExecutionFailure
        false
    end

    def physical_volumes=(new_volumes = [])
        # Only take action if createonly is false just to be safe
        #  this is really only here to enforce the createonly setting
        #  if something goes wrong in physical_volumes
        if @resource[:createonly].to_s == "false"
          existing_volumes = physical_volumes
          extraneous = existing_volumes - new_volumes
          extraneous.each { |volume| reduce_with(volume) }
          missing = new_volumes - existing_volumes
          missing.each { |volume| extend_with(volume) }
        end
    end

    def physical_volumes
        if @resource[:createonly].to_s == "false" || ! vgs(@resource[:name])
          lines = pvs('-o', 'pv_name,vg_name', '--separator', ',')
          lines.split(/\n/).grep(/,#{@resource[:name]}$/).map { |s|
            s.split(/,/)[0].strip
          }
        else
          # Trick the check by setting the returned value to what is
          #  listed in the puppet catalog
          @resource[:physical_volumes]
        end
    end

    private

    def reduce_with(volume)
        vgreduce(@resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not remove physical volume #{volume} from volume group '#{@resource[:name]}'; this physical volume may be in use and may require a manual data migration (using pvmove) before it can be removed (#{detail.message})"
    end

    def extend_with(volume)
        vgextend(@resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not extend volume group '#{@resource[:name]}' with physical volume #{volume} (#{detail.message})"
    end
end
