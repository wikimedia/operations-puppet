# frozen_string_literal: true

Puppet::Type.type(:filesystem).provide :lvm do
  desc 'Manages filesystem of a logical volume on Linux'

  confine kernel: :linux

  commands blkid: 'blkid'

  def create
    mkfs(@resource[:fs_type], @resource[:name])
  end

  def exists?
    fstype == @resource[:fs_type]
  end

  def destroy
    # no-op
  end

  def fstype
    %r{\bTYPE="(\S+)"}.match(blkid(@resource[:name]))[1]
  rescue Puppet::ExecutionFailure
    nil
  end

  def mkfs(fs_type, name)
    mkfs_params = { 'reiserfs' => '-q', 'xfs' => '-f' }

    mkfs_cmd = if @resource[:mkfs_cmd].nil?
                 case fs_type
                 when 'swap'
                   ['mkswap']
                 else
                   ["mkfs.#{fs_type}"]
                 end
               else
                 [@resource[:mkfs_cmd]]
               end

    mkfs_cmd << name

    mkfs_cmd << mkfs_params[fs_type] if mkfs_params[fs_type]

    if resource[:options]
      mkfs_options = Array.new(resource[:options].split)
      mkfs_cmd << mkfs_options
    end

    execute mkfs_cmd
    return unless fs_type == 'swap'

    swap_cmd = ['swapon']
    swap_cmd << name
    execute swap_cmd
  end
end
