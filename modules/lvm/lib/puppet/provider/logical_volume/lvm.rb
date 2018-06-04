Puppet::Type.type(:logical_volume).provide :lvm do
    desc "Manages LVM logical volumes"

    commands :lvcreate   => 'lvcreate',
             :lvremove   => 'lvremove',
             :lvextend   => 'lvextend',
             :lvs        => 'lvs',
             :resize2fs  => 'resize2fs',
             :mkswap     => 'mkswap',
             :swapoff    => 'swapoff',
             :swapon     => 'swapon',
             :umount     => 'umount',
             :blkid      => 'blkid',
             :dmsetup    => 'dmsetup',
             :lvconvert  => 'lvconvert',
             :lvdisplay  => 'lvdisplay'

    optional_commands :xfs_growfs => 'xfs_growfs',
                      :resize4fs  => 'resize4fs'

    def self.instances
      get_logical_volumes.collect do |logical_volumes_line|
        logical_volumes_properties = get_logical_volume_properties(logical_volumes_line)
        new(logical_volumes_properties)
      end
    end

    def self.get_logical_volumes
      full_lvs_output = lvs.split("\n")

      # Remove first line
      logical_volumes = full_lvs_output.drop(1)

      logical_volumes
    end

    def self.get_logical_volume_properties(logical_volumes_line)
      logical_volumes_properties = {}

      # lvs output formats thus:
      # LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert

      # Split on spaces
      output_array = logical_volumes_line.gsub(/\s+/m, ' ').strip.split(" ")

      # Assign properties based on headers
      # Just doing name for now...
      logical_volumes_properties[:ensure]     = :present
      logical_volumes_properties[:name]       = output_array[0]

      logical_volumes_properties
    end

    def create
        args = []

        args.push('-n', @resource[:name]) unless @resource[:thinpool]

        if @resource[:size]
            args.push('--size', @resource[:size])
        elsif @resource[:initial_size]
            args.push('--size', @resource[:initial_size])
        end
        if @resource[:extents]
            args.push('--extents', @resource[:extents])
        end

        if !@resource[:extents] and !@resource[:size] and !@resource[:initial_size]
            args.push('--extents', '100%FREE')
        end

        if @resource[:stripes]
            args.push('--stripes', @resource[:stripes])
        end

        if @resource[:stripesize]
            args.push('--stripesize', @resource[:stripesize])
        end



        if @resource[:poolmetadatasize]
            args.push('--poolmetadatasize', @resource[:poolmetadatasize])
        end

        if @resource[:mirror]
            args.push('--mirrors', @resource[:mirror])
            if @resource[:mirrorlog]
                args.push('--mirrorlog', @resource[:mirrorlog])
            end
            if @resource[:region_size]
                args.push('--regionsize', @resource[:region_size])
            end
            if @resource[:no_sync]
                args.push('--nosync')
            end
        end

        if @resource[:alloc]
            args.push('--alloc', @resource[:alloc])
        end


        if @resource[:readahead]
            args.push('--readahead', @resource[:readahead])
        end

        if @resource[:persistent]
            # if persistent param is true, set arg to "y", otherwise set to "n"
            args.push('--persistent', [:true, true, "true"].include?(@resource[:persistent]) ? 'y' : 'n')
        end

        if @resource[:minor]
            args.push('--minor', @resource[:minor])
        end

        if @resource[:type]
            args.push('--type', @resource[:type])
        end

        if @resource[:thinpool]
            args.push('--thin')
            args << @resource[:volume_group] + "/" + @resource[:name]
        else
            args << @resource[:volume_group]
        end
        lvcreate(*args)
    end

    def destroy
        name_escaped = "#{@resource[:volume_group].gsub('-','--')}-#{@resource[:name].gsub('-','--')}"
        if blkid(path) =~ /\bTYPE=\"(swap)\"/
            swapoff(path)
        end
        dmsetup('remove', name_escaped)
        lvremove('-f', path)
    end

    def exists?
        lvs(@resource[:volume_group]) =~ lvs_pattern
    end

    def size
        if @resource[:size] =~ /^\d+\.?\d{0,2}([KMGTPE])/i
            unit = $1.downcase
        end

        raw = lvs('--noheading', '--unit', unit, path)

        if raw =~ /\s+(\d+)\.(\d+)#{unit}/i
            if $2.to_i == 00
                return $1 + unit.capitalize
            else
                return $1 + '.' + $2.sub(/0+$/, '') + unit.capitalize
            end
        end
    end

    def size=(new_size)
        lvm_size_units = { "K" => 1, "M" => 1024, "G" => 1024**2, "T" => 1024**3, "P" => 1024**4, "E" => 1024**5 }

        resizeable = false
        current_size = size()

        if current_size =~ /^([0-9]+(\.[0-9]+)?)([KMGTPE])/i
            current_size_bytes = $1.to_f
            current_size_unit  = $3.upcase
        end

        if new_size =~ /^([0-9]+(\.[0-9]+)?)([KMGTPE])/i
            new_size_bytes = $1.to_f
            new_size_unit  = $3.upcase
        end

        ## Get the extend size
        if lvs('--noheading', '-o', 'vg_extent_size', '--units', 'k', path) =~ /\s+(\d+)\.\d+k/i
            vg_extent_size = $1.to_i
        end

        ## Verify that it's a extension: Reduce is potentially dangerous and should be done manually
        if lvm_size_units[current_size_unit] < lvm_size_units[new_size_unit]
            resizeable = true
        elsif lvm_size_units[current_size_unit] > lvm_size_units[new_size_unit]
            if (current_size_bytes * lvm_size_units[current_size_unit]) < (new_size_bytes * lvm_size_units[new_size_unit])
                resizeable = true
            end
        elsif lvm_size_units[current_size_unit] == lvm_size_units[new_size_unit]
            if new_size_bytes > current_size_bytes
                resizeable = true
            end
        end

        if not resizeable
            if @resource[:size_is_minsize] == :true or @resource[:size_is_minsize] == true or @resource[:size_is_minsize] == 'true'
                info( "Logical volume already has minimum size of #{new_size} (currently #{current_size})" )
            else
                fail( "Decreasing the size requires manual intervention (#{new_size} < #{current_size})" )
            end
        else
            lvextend( '-L', new_size, path) || fail( "Cannot extend to size #{new_size} because lvextend failed." )

            unless @resource[:resize_fs] == :false or @resource[:resize_fs] == false or @resource[:resize_fs] == 'false'
              begin
                blkid_type = blkid(path)
                if command(:resize4fs) and blkid_type =~ /\bTYPE=\"(ext4)\"/
                  resize4fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
                elsif blkid_type =~ /\bTYPE=\"(ext[34])\"/
                  resize2fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
                elsif blkid_type =~ /\bTYPE=\"(xfs)\"/
                  xfs_growfs( path) || fail( "Cannot resize filesystem to size #{new_size} because xfs_growfs failed." )
                elsif blkid_type =~ /\bTYPE=\"(swap)\"/
                  swapoff( path) && mkswap( path) && swapon( path) || fail( "Cannot resize swap to size #{new_size} because mkswap failed." )
                end
              rescue Puppet::ExecutionFailure => detail
                ## If blkid returned 2, there is no filesystem present or the file doesn't exist.  This should not be a failure.
                if detail.message =~ / returned 2:/
                  Puppet.debug(detail.message)
                end
              end
            end

        end
    end


    # Look up the current number of mirrors (0=no mirroring, 1=1 spare, 2=2 spares....). Return the number as string.
    def mirror
        raw = lvdisplay( path )
        # If the first attribute bit is "m" or "M" then the LV is mirrored.
        if raw =~ /Mirrored volumes\s+(\d+)/im
            # Minus one because it says "2" when there is only one spare. And so on.
            n = ($1.to_i)-1
            #puts " current mirrors: #{n}"
            return n.to_s
        end
        return 0.to_s
    end

    def mirror=( new_mirror_count )
        current_mirrors = mirror().to_i
        if new_mirror_count.to_i != current_mirrors
            puts "Change mirror from #{current_mirrors} to #{new_mirror_count}..."
            args = ['-m', new_mirror_count]
            if @resource[:mirrorlog]
                args.push( '--mirrorlog', @resource[:mirrorlog] )
            end

            # Region size cannot be changed on an existing mirror (not even when changing to zero mirrors).

            if @resource[:alloc]
                args.push( '--alloc', @resource[:alloc] )
            end
            args.push( path )
            lvconvert( *args )
        end
    end

    # Location of the mirror log. Empty string if mirror==0, else "mirrored", "disk" or "core".
    def mirrorlog
        vgname = "#{@resource[:volume_group]}"
        lvname = "#{@resource[:name]}"
        raw = lvs('-a', '-o', '+devices', vgpath)

        if mirror().to_i > 0
            if raw =~ /\[#{lvname}_mlog\]\s+#{vgname}\s+/im
                if raw =~ /\[#{lvname}_mlog\]\s+#{vgname}\s+mw\S+/im #attributes start with "m" or "M"
                    return "mirrored"
                else
                    return "disk"
                end
            else
                return "core"
            end
        end
        return nil
    end

    def mirrorlog=( new_mirror_log_location )
        # It makes no sense to change this unless we use mirrors.
        mirror_count = mirror().to_i
        if mirror_count.to_i > 0
            current_log_location = mirrorlog().to_s
            if new_mirror_log_location.to_s != current_log_location
                #puts "Change mirror log location to #{new_mirror_log_location}..."
                args = [ '--mirrorlog', new_mirror_log_location ]
                if @resource[:alloc]
                    args.push( '--alloc', @resource[:alloc] )
                end
                args.push( path )
                lvconvert( *args )
            end
        end
    end




    private

    def lvs_pattern
        # lvs output format:
        # LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        /\s+#{Regexp.quote @resource[:name]}\s+#{Regexp.quote @resource[:volume_group]}\s+/
    end

    def path
        "/dev/#{@resource[:volume_group]}/#{@resource[:name]}"
    end

    # Device path of only the volume group (does not include the logical volume).
    def vgpath
        "/dev/#{@resource[:volume_group]}"
    end

end
