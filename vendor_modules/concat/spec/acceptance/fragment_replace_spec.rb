# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'replacement of' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'file' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          replace => false,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '1',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '2',
        }

        concat { '#{basedir}/file2':
          replace => true,
        }

        concat::fragment { 'file2_1':
          target  => '#{basedir}/file2',
          content => '1',
        }

        concat::fragment { 'file2_2':
          target  => '#{basedir}/file2',
          content => '2',
        }
      MANIFEST
    end

    it 'when file should not succeed' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match 'file exists'
      expect(file("#{basedir}/file").content).not_to match '1'
      expect(file("#{basedir}/file").content).not_to match '2'
    end
    it 'when file should succeed' do
      expect(file("#{basedir}/file2")).to be_file
      expect(file("#{basedir}/file2").content).not_to match 'file exists'
      expect(file("#{basedir}/file2").content).to match '1'
      expect(file("#{basedir}/file2").content).to match '2'
    end
  end

  describe 'symlink', unless: (os[:family] == 'windows') do
    # XXX the core puppet file type will replace a symlink with a plain file
    # when using ensure => present and source => ... but it will not when using
    # ensure => present and content => ...; this is somewhat confusing behavior
    before(:all) do
      pp = <<-MANIFEST
          file { '#{basedir}':
            ensure => directory,
          }
          file { '#{basedir}/file':
            ensure => link,
            target => '#{basedir}/dangling',
          }
        MANIFEST
      apply_manifest(pp)
    end

    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          replace => false,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '1',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '2',
        }

        concat { '#{basedir}/file2':
          replace => true,
        }

        concat::fragment { 'file2_1':
          target  => '#{basedir}/file2',
          content => '1',
        }

        concat::fragment { 'file2_2':
          target  => '#{basedir}/file2',
          content => '2',
        }
      MANIFEST
    end

    it 'when symlink should not succeed' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_linked_to "#{basedir}/dangling" unless os[:family] == 'aix' || os[:family] == 'windows'
      expect(file("#{basedir}/dangling")).not_to be_file
      expect(file("#{basedir}/dangling")).not_to be_directory
    end
    it 'when symlink should succeed' do
      expect(file("#{basedir}/file2")).to be_file
      expect(file("#{basedir}/file2").content).to match '1'
      expect(file("#{basedir}/file2").content).to match '2'
    end
  end

  describe 'when directory should not succeed' do
    before(:all) do
      pp = <<-MANIFEST
          file { '#{basedir}':
            ensure => directory,
          }
          file { '#{basedir}/file':
            ensure => directory,
          }
        MANIFEST
      apply_manifest(pp)
    end
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file': }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '1',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '2',
        }
      MANIFEST
    end

    it 'applies the manifest twice with stderr' do
      expect(apply_manifest(pp, expect_failures: true).stderr).to match(%r{change from '?directory'? to '?file'? failed})
      expect(apply_manifest(pp, expect_failures: true).stderr).to match(%r{change from '?directory'? to '?file'? failed})
      expect(file("#{basedir}/file")).to be_directory
    end
  end

  # XXX
  # when there are no fragments, and the replace param will only replace
  # files and symlinks, not directories.  The semantics either need to be
  # changed, extended, or a new param introduced to control directory
  # replacement.
  describe 'when directory should succeed', pending: 'not yet implemented' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '1',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '2',
        }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '1'
    end
  end
end
