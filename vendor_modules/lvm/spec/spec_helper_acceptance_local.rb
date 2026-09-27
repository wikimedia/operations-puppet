# frozen_string_literal: true

require 'singleton'
require 'puppet_litmus'
require 'open3'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

# Verify if a physical volume, volume group, logical volume, or filesystem resource type is created
#
# ==== Attributes
#
# * +resource_type+ - resorce type, i.e 'physical_volume', 'volume_group', 'logical_volume', 'filesystem',
# *                   'aix_physical_volume', 'aix_volume_group', or 'aix_logical_volume'.
# * +resource_name+ - The name of resource type, i.e '/dev/sdb' for physical volume, vg_1234 for volume group
# * +vol_group+ - volume group name associated with logical volume (if any)
# * +properties+ - a matching string or regular expression in logical volume properties
# ==== Returns
#
# +nil+
#
# ==== Raises
# assert_match failure message
# ==== Examples
#
# verify_if_created?(agent, 'physical_volume', /dev/sdb', VolumeGroup_123, "Size     7GB")
def verify_if_created?(resource_type, resource_name, vol_group = nil, properties = nil)
  case resource_type
  when 'physical_volume'
    LitmusHelper.instance.run_shell('pvdisplay') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'volume_group'
    LitmusHelper.instance.run_shell('vgdisplay') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'logical_volume'
    raise ArgumentError, 'Missing volume group that the logical volume is associated with' unless vol_group

    LitmusHelper.instance.run_shell("lvdisplay /dev/#{vol_group}/#{resource_name}") do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
      assert_match(%r{#{properties}}, result.stdout, 'Unexpected error was detected') if properties
    end
  when 'aix_physical_volume'
    LitmusHelper.instance.run_shell("lspv #{resource_name}") do |result|
      assert_match(%r{Physical volume #{resource_name} is not assigned to}, result.stdout, 'Unexpected error was detected')
    end
  when 'aix_volume_group'
    LitmusHelper.instance.run_shell('lsvg') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'aix_logical_volume'
    raise ArgumentError, 'Missing volume group that the logical volume is associated with' unless vol_group

    LitmusHelper.instance.run_shell("lslv #{resource_name}") do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
      assert_match(%r{#{properties}}, result.stdout, 'Unexpected error was detected') if properties
    end
  end
end

def install_dependencies
  pp = <<-MANIFEST
    package { 'lvm2':
      ensure => 'latest',
    }
  MANIFEST
  LitmusHelper.instance.apply_manifest(pp)
end

def run_remote_shell_with_retry(command, retries: 3, delay: 3)
  attempt = 0

  begin
    LitmusHelper.instance.run_shell(command)
  rescue RuntimeError => e
    retryable_error = e.message.match?(%r{connection reset|connect-error|timed out|temporar|rate limit}i)
    if retryable_error && attempt < retries
      sleep(delay * (attempt + 1))
      attempt += 1
      retry
    end

    warn("Cleanup command failed: #{command}\n#{e.message}")
  end
end

def run_local_gcloud_with_retry(command, retries: 3, delay: 3, capture3: Open3.method(:capture3), sleeper: method(:sleep), warning: method(:warn))
  attempt = 0
  combined_output = ''

  loop do
    stdout, stderr, status = capture3.call(command)
    return :done if status.success?

    combined_output = "#{stdout}\n#{stderr}"
    return :done if combined_output.match?(%r{not found}i)
    return :auth_error if combined_output.match?(%r{do not currently have an active account selected|gcloud auth login}i)

    break unless combined_output.match?(%r{connection reset|timed out|temporar|rate limit}i) && attempt < retries

    sleeper.call(delay * (attempt + 1))
    attempt += 1
  end

  warning.call("Cleanup command failed: #{command}\n#{combined_output}")
  :done
end

def run_gcloud_cleanup_command(command)
  run_remote_shell_with_retry(command) if run_local_gcloud_with_retry(command) == :auth_error
end

# Clean the box after each test, make sure the newly created logical volumes, volume groups,
# and physical volumes are removed at the end of each test to make the server ready for the
# next test case.
#
# ==== Attributes
#
# * +physical_volume+ - physical volume, can be one volume or an array of multiple volumes
# * +vol_group+ - volume group, can be one group or an array of multiple volume groups
# * +logical_volume+ - logical volume, can be one volume or an array of multiple volumes
# * +aix+ - if the agent is an AIX server.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
# +nil+
# ==== Examples
#
# remove_all('/dev/sdb', 'VolumeGroup_1234', 'LogicalVolume_fa13')
def remove_all(physical_volume = nil, vol_group = nil, logical_volume = nil, aix = false)
  if aix
    LitmusHelper.instance.run_shell("reducevg -d -f #{vol_group} #{physical_volume}")
    LitmusHelper.instance.run_shell("rm -rf /dev/#{vol_group} /dev/#{logical_volume}")
  else
    if logical_volume
      if logical_volume.is_a?(Array)
        logical_volume.each do |logical_volume|
          LitmusHelper.instance.run_shell("umount /dev/#{vol_group}/#{logical_volume}", expect_failures: true)
          LitmusHelper.instance.run_shell("lvremove /dev/#{vol_group}/#{logical_volume} --force", expect_failures: true)
        end
      else
        # NOTE: in some test cases, for example, the test case 'create_vg_property_logical_volume'
        # the logical volume must be unmount before being able to delete it
        LitmusHelper.instance.run_shell("umount /dev/#{vol_group}/#{logical_volume}", expect_failures: true)
        LitmusHelper.instance.run_shell("lvremove /dev/#{vol_group}/#{logical_volume} --force", expect_failures: true)
      end
    end

    if vol_group
      if vol_group.is_a?(Array)
        vol_group.each do |volume_group|
          LitmusHelper.instance.run_shell("vgremove /dev/#{volume_group}")
        end
      else
        LitmusHelper.instance.run_shell("vgremove /dev/#{vol_group}")
      end
    end

    if physical_volume
      if physical_volume.is_a?(Array)
        physical_volume.each do |physical_volume|
          LitmusHelper.instance.run_shell("pvremove #{physical_volume}")
        end
      else
        LitmusHelper.instance.run_shell("pvremove #{physical_volume}")
      end
    end
  end
end

unless ENV['LVM_SKIP_ACCEPTANCE_SETUP'] == 'true'
  RSpec.configure do |c|
    disks = ['sdb', 'sdc']
    hostname = LitmusHelper.instance.run_shell('hostname').stdout.strip.gsub(%r{\..*$}, '')
    zone = LitmusHelper.instance.run_shell('curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone').stdout.strip.gsub(%r{.*zones/}, '')
    c.before :suite do
      install_dependencies
      disks.each do |disk|
        LitmusHelper.instance.run_shell("gcloud compute disks create #{hostname}-#{disk} --size 10GB --type pd-standard --zone=#{zone}")
        LitmusHelper.instance.run_shell("gcloud compute instances attach-disk #{hostname} --disk #{hostname}-#{disk} --zone=#{zone}")
      end
    end
    c.after :suite do
      disks.each do |disk|
        run_gcloud_cleanup_command("gcloud compute instances detach-disk #{hostname} --disk=#{hostname}-#{disk} --zone=#{zone} --quiet")
        run_gcloud_cleanup_command("gcloud compute disks delete #{hostname}-#{disk} --zone=#{zone} --quiet")
      end
    end
  end
end
