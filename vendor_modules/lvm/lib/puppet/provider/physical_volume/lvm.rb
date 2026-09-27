# frozen_string_literal: true

Puppet::Type.type(:physical_volume).provide(:lvm) do
  desc 'Manages LVM physical volumes on Linux'

  confine kernel: :linux

  commands pvcreate: 'pvcreate', pvremove: 'pvremove', pvs: 'pvs', vgs: 'vgs'

  def self.instances
    get_physical_volumes.map do |physical_volumes_line|
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
    if vg_exists
      # If the VG exists return true
      true
    else
      begin
        # Check to see if the PV already exists
        pvs(@resource[:name])
      rescue Puppet::ExecutionFailure
        false
      end
    end
  end

  def self.get_physical_volumes
    full_pvs_output = pvs.split("\n")

    # Remove first line
    full_pvs_output.drop(1)
  end

  def self.get_physical_volume_properties(physical_volumes_line)
    physical_volumes_properties = {}

    # pvs output formats thus:
    # PV         VG       Fmt  Attr PSize  PFree

    # Split on spaces
    output_array = physical_volumes_line.gsub(%r{\s+}m, ' ').strip.split

    # Assign properties based on headers
    # Just doing name for now...
    physical_volumes_properties[:ensure]     = :present
    physical_volumes_properties[:name]       = output_array[0]

    physical_volumes_properties
  end

  private

  def create_physical_volume(path)
    args = []
    args.push('--force') if @resource[:force] == :true
    args << path
    pvcreate(*args)
  end
end
