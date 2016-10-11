require 'pathname'

Puppet::Type.newtype(:filesystem) do

  desc "The filesystem type"

  ensurable

  newparam(:fs_type) do
    desc "The file system type. eg. ext3."
  end

  newparam(:name) do
    isnamevar
    validate do |value|
      unless Pathname.new(value).absolute?
        raise ArgumentError, "Filesystem names must be fully qualified"
      end
    end
  end

  newparam(:mkfs_cmd) do
    desc "Command to use to create the file system. Defaults to mkswap for fs_type=swap, otherwise mkfs.{{fs_type}}"
  end

  newparam(:options) do
    desc "Params for the mkfs command. eg. -l internal,agcount=x"
  end

  newparam(:initial_size) do
    desc "Initial size of the filesystem, Used only for resource creation, when using this option Puppet will not manage or maintain the size. To resize filesystems see the size property. AIX only."
  end

  newproperty(:size) do
    desc "Configures the size of the filesystem.  Supports filesystem resizing.  The size will be rounded up to the nearest multiple of the partition size. AIX only."
  end

  newparam(:ag_size) do
    desc "Specify the allocation group size in megabytes, AIX only."
    newvalues(/\d+/)
  end   
          
  newparam(:large_files) do
    desc "Large file enabled file system.  AIX only"
    newvalues(:true, :false)
  end       

  newparam(:compress) do
    desc "Data compression, LZ or no. AIX only"
    newvalues(:LG, :no)
  end

  newparam(:frag) do
    desc "JFS fragment size in bytes. AIX only"
    newvalues(/\d+/)
  end 
   
  newparam(:nbpi) do
    desc "Bytes per inode. AIX only"
    newvalues(/\d+/)
  end

  newparam(:logname) do
    desc "Configure the log logical volume. AIX only"
  end

  newparam(:logsize) do
    desc "Size for an inline log in MB, AIX only"
    newvalues(/\d+/)
  end

  newparam(:maxext) do
    desc "Size of a file extent in file system blocks, AIX only"
    newvalues(/\d+/)
  end

  newparam(:mountguard) do
    desc "Enable the mountguard. AIX only"
    newvalues(:true, :false)
  end

  newparam(:agblksize) do
    desc "JFS2 block size in bytes, AIX only."
    newvalues(/\d+/)
  end

  newparam(:extended_attributes) do
    desc "Format to be used to store extended attributes. AIX only"
    newvalues(:v1,:v2)
  end

  newparam(:encrypted) do
    desc "Specify and encrypted filesystem. AIX only"
    newvalues(:true,:false)
  end
  newparam(:isnapshot) do
    desc "Specify whether the filesystem supports internal snapshots, AIX only"
    newvalues(:true, :false)
  end

  newparam(:mount_options) do
    desc "Specify the options to be passed to the mount command. AIX only"
  end

  newparam(:vix) do
    desc "Specify that the file system can allocate inode extents smaller than the default, AIX only"
    newvalues(:true, :false)
  end

  newparam(:log_partitions) do
    desc "Specify the size of the log logical volume as number of logical partitions, AIX only"
  end

  newparam(:nodename) do
    desc "Specify the remote host where the filesystem resides. AIX only"
  end

  newparam(:accounting) do
    desc "Specify accounting subsystem support, AIX only"
    newvalues(:true, :false)
  end

  newparam(:mountgroup) do
    desc "Mount group for the filesystem, AIX only"
  end

  newparam(:atboot) do
    desc "Specify whether the file system is mounted at boot time, AIX only"
    newvalues(:true, :false)
  end

  newparam(:perms) do
    desc "Permissions for the filesystem, AIX only"
    newvalues(:ro, :rw)
  end

  newparam(:device) do
    desc "Device to create the filesystem on, this can be a device or a logical volume. AIX only"
  end

  newparam(:volume_group) do
    desc "Volume group that the file system should be greated on. AIX only."
  end

  autorequire(:logical_volume) do
    if device = @parameters[:device]
      device.value
    else
      @parameters[:name].value
    end
  end
end
