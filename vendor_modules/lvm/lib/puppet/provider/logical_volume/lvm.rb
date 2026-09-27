# frozen_string_literal: true

Puppet::Type.type(:logical_volume).provide :lvm do
  desc 'Manages LVM logical volumes on Linux'

  confine kernel: :linux

  commands lvcreate: 'lvcreate',
           lvremove: 'lvremove',
           lvextend: 'lvextend',
           lvs: 'lvs',
           resize2fs: 'resize2fs',
           mkswap: 'mkswap',
           swapoff: 'swapoff',
           swapon: 'swapon',
           umount: 'umount',
           blkid: 'blkid',
           dmsetup: 'dmsetup',
           lvconvert: 'lvconvert',
           lvdisplay: 'lvdisplay',
           lsblk: 'lsblk'

  optional_commands xfs_growfs: 'xfs_growfs',
                    resize4fs: 'resize4fs',
                    udevadm: 'udevadm'

  def self.instances
    get_logical_volumes.map do |logical_volumes_line|
      logical_volumes_properties = get_logical_volume_properties(logical_volumes_line)
      instance = new(logical_volumes_properties)
      # Save the volume group in the provider so the type can find it
      instance.volume_group = logical_volumes_properties[:volume_group]
      instance
    end
  end

  def self.get_logical_volumes
    full_lvs_output = lvs.split("\n")

    # Remove first line
    full_lvs_output.drop(1)
  end

  def self.get_logical_volume_properties(logical_volumes_line)
    logical_volumes_properties = {}

    # lvs output formats thus:
    # LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert

    # Split on spaces
    output_array = logical_volumes_line.gsub(%r{\s+}m, ' ').strip.split

    # Assign properties based on headers
    logical_volumes_properties[:ensure]       = :present
    logical_volumes_properties[:name]         = output_array[0]
    logical_volumes_properties[:volume_group] = output_array[1]

    logical_volumes_properties
  end

  # Just assume that the volume group is correct, we don't support changing
  # it anyway.
  attr_writer :volume_group

  def volume_group
    @resource ? @resource[:volume_group] : @volume_group
  end

  def create
    args = []

    args.push('-n', @resource[:name]) unless @resource[:thinpool] == true

    size_option = '--size'
    size_option = '--virtualsize' if @resource[:thinpool].is_a? String

    if @resource[:size]
      args.push(size_option, @resource[:size])
    elsif @resource[:initial_size]
      args.push(size_option, @resource[:initial_size])
    end
    args.push('--extents', @resource[:extents]) if @resource[:extents]

    args.push('--extents', '100%FREE') if !@resource[:extents] && !@resource[:size] && !@resource[:initial_size]

    args.push('--stripes', @resource[:stripes]) if @resource[:stripes]

    args.push('--stripesize', @resource[:stripesize]) if @resource[:stripesize]

    args.push('--poolmetadatasize', @resource[:poolmetadatasize]) if @resource[:poolmetadatasize]

    if @resource[:mirror]
      args.push('--mirrors', @resource[:mirror])
      args.push('--mirrorlog', @resource[:mirrorlog]) if @resource[:mirrorlog]
      args.push('--regionsize', @resource[:region_size]) if @resource[:region_size]
      args.push('--nosync') if @resource[:no_sync]
    end

    args.push('--alloc', @resource[:alloc]) if @resource[:alloc]

    args.push('--readahead', @resource[:readahead]) if @resource[:readahead]

    if @resource[:persistent]
      # if persistent param is true, set arg to "y", otherwise set to "n"
      args.push('--persistent', [:true, true, 'true'].include?(@resource[:persistent]) ? 'y' : 'n')
    end

    args.push('--minor', @resource[:minor]) if @resource[:minor]

    args.push('--type', @resource[:type]) if @resource[:type]

    if @resource[:thinpool]
      args.push('--thin')
      args << if @resource[:thinpool].is_a? String
                "#{@resource[:volume_group]}/#{@resource[:thinpool]}"
              else
                "#{@resource[:volume_group]}/#{@resource[:name]}"
              end
    else
      args << @resource[:volume_group]
    end

    args.push('--yes') if @resource[:yes_flag]
    lvcreate(*args)
    settle_udev
  end

  def destroy
    name_escaped = "#{@resource[:volume_group].gsub('-', '--')}-#{@resource[:name].gsub('-', '--')}"
    swapoff(path) if %r{\bTYPE="(swap)"}.match?(blkid(path))
    dmsetup('remove', name_escaped)
    lvremove('-f', path)
  end

  def exists?
    lvs(@resource[:volume_group]) =~ lvs_pattern
  rescue Puppet::ExecutionFailure
    # lvs fails if we give it an empty volume group name, as would
    # happen if we were running `puppet resource`. This should be
    # interpreted as "The resource does not exist"
    nil
  end

  def size
    unit = if @resource[:size] =~ %r{^\d+\.?\d{0,2}([KMGTPE])}i
             Regexp.last_match(1).downcase
           else
             # If we are getting the size initially we don't know what the
             # units will be, default to GB
             'g'
           end

    raw = lvs('--noheading', '--unit', unit, path)

    return unless raw =~ %r{\s+(\d+)\.(\d+)#{unit}}i
    return Regexp.last_match(1) + unit.capitalize if Regexp.last_match(2).to_i.zero?

    "#{Regexp.last_match(1)}.#{Regexp.last_match(2).sub(%r{0+$}, '')}#{unit.capitalize}"
  end

  def size=(new_size)
    lvm_size_units = { 'K' => 1, 'M' => 1024, 'G' => 1024**2, 'T' => 1024**3, 'P' => 1024**4, 'E' => 1024**5 }

    resizeable = false
    current_size = size

    if current_size =~ %r{^([0-9]+(\.[0-9]+)?)([KMGTPE])}i
      current_size_bytes = Regexp.last_match(1).to_f
      current_size_unit = Regexp.last_match(3).upcase
    end

    if new_size =~ %r{^([0-9]+(\.[0-9]+)?)([KMGTPE])}i
      new_size_bytes = Regexp.last_match(1).to_f
      new_size_unit = Regexp.last_match(3).upcase
    end

    ## Get the extend size
    vg_extent_size = Regexp.last_match(1).to_i if lvs('--noheading', '-o', 'vg_extent_size', '--units', 'k', path) =~ %r{\s+(\d+)\.\d+k}i

    ## Verify that it's a extension: Reduce is potentially dangerous and should be done manually
    if lvm_size_units[current_size_unit] < lvm_size_units[new_size_unit]
      resizeable = true
    elsif lvm_size_units[current_size_unit] > lvm_size_units[new_size_unit]
      resizeable = true if (current_size_bytes * lvm_size_units[current_size_unit]) < (new_size_bytes * lvm_size_units[new_size_unit])
    elsif lvm_size_units[current_size_unit] == lvm_size_units[new_size_unit]
      resizeable = true if new_size_bytes > current_size_bytes
    end

    if resizeable
      args = []
      args.push('--yes') if @resource[:yes_flag]

      lvextend('-L', new_size, path, *args) || raise("Cannot extend to size #{new_size} because lvextend failed.")

      unless [:false, false, 'false'].include?(@resource[:resize_fs])
        begin
          blkid_type = blkid(path)
          if command(:resize4fs) && blkid_type =~ %r{\bTYPE="(ext4)"}
            resize4fs(path) || raise("Cannot resize file system to size #{new_size} because resize2fs failed.")
          elsif %r{\bTYPE="(ext[34])"}.match?(blkid_type)
            resize2fs(path) || raise("Cannot resize file system to size #{new_size} because resize2fs failed.")
          elsif %r{\bTYPE="(xfs)"}.match?(blkid_type)
            # New versions of xfs_growfs only support resizing by mount point, not by volume (e.g. under RHEL8)
            # * https://tickets.puppetlabs.com/browse/MODULES-9004
            mount_point = lsblk('-o', 'MOUNTPOINT', '-nr', path).chomp
            xfs_growfs(mount_point) || raise("Cannot resize filesystem to size #{new_size} because xfs_growfs failed.")
          elsif %r{\bTYPE="(swap)"}.match?(blkid_type)
            (swapoff(path) && mkswap(path) && swapon(path)) || raise("Cannot resize swap to size #{new_size} because mkswap failed.")
          end
        rescue Puppet::ExecutionFailure => e
          ## If blkid returned 2, there is no filesystem present or the file doesn't exist.  This should not be a failure.
          Puppet.debug(e.message) if e.message.include?(' returned 2:') # rubocop:disable Metrics/BlockNesting
        end
      end

    else
      unless [:true, true, 'true'].include?(@resource[:size_is_minsize])
        raise Puppet::Error, "Decreasing the size requires manual intervention (#{new_size} < #{current_size})"
      end

      info("Logical volume already has minimum size of #{new_size} (currently #{current_size})")

    end
  end

  def stripes
    # Run the lvs command with the -o option to get only the stripes count
    raw = (lvs '-o', 'stripes', '--noheadings', path)

    output_array = raw.strip
    output_array
  end

  def stripes=(new_stripes_count)
    current_stripes = stripes.to_i

    # Changing stripes is not supported for existing logical volumes
    return unless new_stripes_count.to_i != current_stripes
    raise Puppet::Error, "Changing stripes from #{current_stripes} to #{new_stripes_count} is not supported for existing logical volumes"
  end

  # Look up the current number of mirrors (0=no mirroring, 1=1 spare, 2=2 spares....). Return the number as string.
  def mirror
    raw = lvdisplay(path)
    # If the first attribute bit is "m" or "M" then the LV is mirrored.
    if raw =~ %r{Mirrored volumes\s+(\d+)}im
      # Minus one because it says "2" when there is only one spare. And so on.
      n = Regexp.last_match(1).to_i - 1
      # puts " current mirrors: #{n}"
      return n.to_s
    end
    0.to_s
  end

  def mirror=(new_mirror_count)
    current_mirrors = mirror.to_i
    return unless new_mirror_count.to_i != current_mirrors

    puts "Change mirror from #{current_mirrors} to #{new_mirror_count}..."
    args = ['-m', new_mirror_count]
    args.push('--mirrorlog', @resource[:mirrorlog]) if @resource[:mirrorlog]

    # Region size cannot be changed on an existing mirror (not even when changing to zero mirrors).

    args.push('--alloc', @resource[:alloc]) if @resource[:alloc]
    args.push(path)
    lvconvert(*args)
  end

  # Location of the mirror log. Empty string if mirror==0, else "mirrored", "disk" or "core".
  def mirrorlog
    vgname = @resource[:volume_group].to_s
    lvname = @resource[:name].to_s
    raw = lvs('-a', '-o', '+devices', vgpath)

    if mirror.to_i.positive?
      return 'core' unless %r{\[#{lvname}_mlog\]\s+#{vgname}\s+}im.match?(raw)
      return 'mirrored' if %r{\[#{lvname}_mlog\]\s+#{vgname}\s+mw\S+}im.match?(raw) # attributes start with "m" or "M"

      return 'disk'

    end
    nil
  end

  def mirrorlog=(new_mirror_log_location)
    # It makes no sense to change this unless we use mirrors.
    mirror_count = mirror.to_i
    return unless mirror_count.to_i.positive?

    current_log_location = mirrorlog.to_s
    return unless new_mirror_log_location.to_s != current_log_location

    # puts "Change mirror log location to #{new_mirror_log_location}..."
    args = ['--mirrorlog', new_mirror_log_location]
    args.push('--alloc', @resource[:alloc]) if @resource[:alloc]
    args.push(path)
    lvconvert(*args)
  end

  private

  # Wait for udev to finish processing events triggered by lvcreate so the
  # device node is fully settled before downstream resources (e.g. filesystem)
  # try to open it. Without this, mkfs can race and fail with EBUSY.
  def settle_udev
    if self.class.udevadm_available?
      begin
        udevadm('settle', '--timeout=30')
      rescue Puppet::ExecutionFailure
        Puppet.warning("udevadm settle returned non-zero after lvcreate of #{@resource[:name]}; the device may not be fully ready")
      end
    else
      Puppet.debug('udevadm not present, skipping settle')
    end
  end

  # Cached at class level so we lookup `udevadm` once per process rather than
  # once per resource. `command(:udevadm)` is generated by `optional_commands`
  # above and returns the resolved path or nil — same source of truth, no
  # second `which` call.
  def self.udevadm_available?
    return @udevadm_available if defined?(@udevadm_available)
    @udevadm_available = !command(:udevadm).nil?
  end

  def lvs_pattern
    # lvs output format:
    # LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
    %r{\s+#{Regexp.quote @resource[:name]}\s+#{Regexp.quote @resource[:volume_group]}\s+}
  end

  def path
    "/dev/#{@resource[:volume_group]}/#{@resource[:name]}"
  end

  # Device path of only the volume group (does not include the logical volume).
  def vgpath
    "/dev/#{@resource[:volume_group]}"
  end
end
