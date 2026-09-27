# frozen_string_literal: true

require 'open3'
Puppet::Type.type(:logical_volume).provide :aix do
  desc 'Manages LVM logical volumes on AIX'
  defaultfor 'os.name': :AIX
  confine 'os.name': :AIX

  commands mklv: 'mklv'

  def create
    # Dont use auto-generated LG names as we need to know what resource
    # we are managing
    args = ['-y', @resource[:name]]
    if @resource[:range]
      args << '-e'
      case @resource[:range]
      when 'maximum'
        args << 'x'
      when 'minimum'
        args << 'm'
      end
    end

    args.push('-t', @resource[:type]) if @resource[:type]

    args.push(@resource[:volume_group], @resource[:initial_size])

    mklv(*args)
  end

  def exists?
    Open3.popen3("lslv #{@resource[:name]}")[3].value.success?
  end
end
