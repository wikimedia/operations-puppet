# frozen_string_literal: true

Puppet::Type.type(:volume_group).provide :aix do
  desc 'Manages LVM volume groups on AIX'
  # defaultof :operatingsystem => AIX
  # confine :operatingsystem => AIX

  commands mkvg: 'mkvg',
           # :vgremove => 'vgremove',
           lsvg: 'lsvg',
           extendvg: 'extendvg',
           reducevg: 'reducevg',
           lspv: 'lspv'

  def create
    mkvg('-y', @resource[:name], *@resource.should(:physical_volumes))
  end

  def destroy
    reducevg('-df', @resource[:name], *@resource.should(:physical_volumes))
  end

  def exists?
    lsvg(@resource[:name])
  rescue Puppet::ExecutionFailure
    false
  end

  def physical_volumes=(new_volumes = [])
    # Only take action if createonly is false just to be safe
    #  this is really only here to enforce the createonly setting
    #  if something goes wrong in physical_volumes
    return unless @resource[:createonly].to_s == 'false'

    existing_volumes = physical_volumes
    extraneous = existing_volumes - new_volumes
    extraneous.each { |volume| reduce_with(volume) }
    missing = new_volumes - existing_volumes
    missing.each { |volume| extend_with(volume) }
  end

  def physical_volumes
    if @resource[:createonly].to_s == 'false' || !lsvg(@resource[:name])
      lines = lspv
      lines.split(%r{\n}).grep(%r{#{@resource[:name]}}).map do |s|
        s.split(%r{\W+})[0].strip
      end
    else
      # Trick the check by setting the returned value to what is
      #  listed in the puppet catalog
      @resource[:physical_volumes]
    end
  end

  private

  def reduce_with(volume)
    reducevg(@resource[:name], volume)
  rescue Puppet::ExecutionFailure => e
    raise Puppet::Error, "Could not remove physical volume #{volume} from volume group '#{@resource[:name]}'; this physical volume may " \
        + "be in use and may require a manual data migration (using pvmove) before it can be removed (#{e.message})"
  end

  def extend_with(volume)
    extendvg(@resource[:name], volume)
  rescue Puppet::ExecutionFailure => e
    raise Puppet::Error, "Could not extend volume group '#{@resource[:name]}' with physical volume #{volume} (#{e.message})"
  end
end
