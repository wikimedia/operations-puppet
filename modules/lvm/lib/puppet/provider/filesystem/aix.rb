require 'open3'
Puppet::Type.type(:filesystem).provide :aix do

  desc "Manages logical volume filesystems on AIX"

  confine :operatingsystem => :AIX
  defaultfor :operatingsystem => :AIX

  commands :crfs => 'crfs',
           :chfs => 'chfs'

  def exists?
    Open3.popen3("lsfs #{@resource[:name]}")[3].value.success?
  end

  def create
    args = []

    attributes=[
      :ag_size,
      :large_files,
      :compress,
      :frag,
      :nbpi,
      :logname,
      :size,
      :initial_size,
      :encrypted,
      :isnapshot,
      :logsize,
      :maxext,
      :mountguard,
      :agblksize,
      :extended_attributes,
      :mount_options,
      :vix
    ]

    args.push(*add_attributes(*attributes))

    args.push(*add_flag(:v, :fs_type))
    args.push(*add_flag(:m, :name))
    args.push(*add_flag(:d, :device))
    args.push(*add_flag(:l, :log_partitions))
    args.push(*add_flag(:g, :volume_group))
    args.push(*add_flag(:A, :atboot))
    args.push(*add_flag(:p, :perms))
    crfs(*args)

    # crfs on AIX will ignore -a size if the logical_volume already
    # has a size and is specified as -d. So to be sure we sync the
    # size property after creation
    if @resource[:size]
      if size != @resource[:size]
        self.size= (@resource[:size])
      end
    end
      
  end

  def attribute_flag(pvalue)
    {
      :ag_size              => 'ag',
      :large_file           => 'bf',
      :initial_size         => 'size',
      :size                 => 'size',
      :extended_attributes  => 'ea',
      :mount_options        => 'options',
      :encrypted            => 'efs'
    }[pvalue] || pvalue.to_s
  end

  def add_attributes(*args)
    attr_args=[]
    args.each do |arg|
      if @resource[arg]
        ans=parse_boolean(@resource[arg])
        attr_args.push('-a', "#{attribute_flag(arg)}=#{@resource[arg]}")
      end
    end
    attr_args
  end

  def add_flag(flag,param)
    if @resource[param]
      [ "-#{flag.to_s}", "#{parse_boolean(@resource[param])}" ]
    end
  end

  def parse_boolean(param)
    case param
    when :true
      'yes'
    when :false
      'no'
    else
      param
    end
  end

  def size
    cursize=0
    reqsize=blk_roundup(val_to_blk(@resource[:size]))

    Open3.popen3("lsfs -q #{@resource[:name]}") do |stdin, stdout, stderr|
      stdout.each do |line|
        elements=line.split(/\s+/)
        if elements[2] == @resource[:name]
          cursize=elements[4].to_i
        end
      end
    end

    if cursize == reqsize
      @resource[:size]
    else
      blk_to_val(cursize,@resource[:size][-1,1])
    end
  end

  def size=(newsize)
    chfs('-a',"size=#{@resource[:size]}", @resource[:name])
  end

  def val_to_blk(val)
    input = val.match(/(\d+)([^0-9]|)/).to_a
    case input[2]
    when 'M'
      input[1].to_i*1024*2
    when 'G'
      input[1].to_i*1024*1024*2
    else
      input[1].to_i
    end
  end

  def blk_to_val(blocks,units=nil)
    case units
    when 'M'
      sprintf('%gM', Float(blocks.to_i/2/1024))
    when 'G'
      sprintf('%gM', Float(blocks.to_i/2/1024/1024))
    else
      blocks
    end
  end

  def blk_roundup(blocks)
    ppsize=Integer(pp_size*1024*2)
    ppsize*Float(Float(blocks)/ppsize).ceil.to_i
  end

  def pp_size
    vg = @resource[:volume_group] || 'rootvg'
    Open3.capture2("lsvg #{vg} | /bin/grep 'PP SIZE'")[0].split(/\s+/)[5].to_i
  end

  def attribute_flag(pvalue)
    {
      :ag_size              => 'ag',
      :large_file           => 'bf',
      :initial_size         => 'size',
      :size                 => 'size',
      :extended_attributes  => 'ea',
      :mount_options        => 'options',
      :encrypted            => 'efs'
    }[pvalue] || pvalue.to_s
  end
end
