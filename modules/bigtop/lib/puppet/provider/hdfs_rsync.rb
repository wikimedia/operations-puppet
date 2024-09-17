# SPDX-License-Identifier: Apache-2.0
require 'puppet/util'
require 'tempfile'
require 'fileutils'

Puppet::Type.type(:hdfs_file).provide(:hdfs_rsync) do
  desc "A custom provider to manage files on HDFS using hdfs_rsync, with local temp files for content/source."

  # This provider will only function when the HDFS user is present and has a keytab.
  confine :exists => "/etc/security/keytabs/hadoop/hdfs.keytab"
  confine :exists => "/usr/local/bin/kerberos-run-command"
  confine :exists => "/usr/local/bin/hdfs-rsync"
  confine :exists => "/usr/bin/hdfs"

  commands :hdfs_rsync => "/usr/bin/sudo -u hdfs /usr/local/bin/kerberos-run-command /usr/bin/hdfs /usr/local/bin/hdfs-rsync"
  commands :hdfs => "/usr/bin/sudo -u hdfs /usr/local/bin/kerberos-run-command /usr/bin/hdfs hdfs"

  # Check if the file exists on HDFS
  def exists?
    # We use hdfs_rsync to check if the file exists on the HDFS path
    Puppet.notice("Checking existence of #{@resource[:path]} on HDFS")
    hdfs("dfs", "-test", "-e", @resource[:path])
  end

  # Create the file using a local temporary file and hdfs_rsync to HDFS
  def create
    Puppet.notice("Creating file on HDFS using temporary local file")
    create_update_file
  end

  # Modify the file content based on content or source
  def content
    Puppet.notice("Modifying file on HDFS using temporary local file")
    create_update_file
  end

  # Destroy the file on HDFS
  def destroy
    Puppet.notice("Removing file from HDFS #{@resource[:path]}")
    hdfs("dfs -rm", @resource[:path])
  end

  def create_update_file
    Tempfile.create('tempfile') do |tmpfile|
      if @resource[:content]
        Puppet.notice("Writing new inline content to temporary file")
        tmpfile.write(@resource[:content])
        tmpfile.flush # Ensure content is written to disk
      elsif @resource[:source]
        Puppet.notice("Copying updated content from source #{@resource[:source]} to temporary file")
        FileUtils.cp(@resource[:source], tmpfile.path)
      end
      # Use hdfs_rsync to sync the temporary file to the HDFS path
      Puppet.notice("Syncing updated temporary file to HDFS #{@resource[:path]}")
      # rubocop:disable Metrics/LineLength
      hdfs_rsync("--perms", "--chown=#{@resource[:owner]}", "--chgrp=#{@resource[:group]}", "--chmod=#{@resource[:mode]}", "file://#{tmpfile.path}", "hdfs://#{@resource[:path].dirname}")
      # rubocop:enable Metrics/LineLength
    end
  end
end
