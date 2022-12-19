# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat ensure_newline parameter' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'when false' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        ensure_newline => false,
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
      expect(file("#{basedir}/file").content).to match '12'
    end
  end

  describe 'when true' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        ensure_newline => true,
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
      expect(file("#{basedir}/file").content).to match %r{1\r?\n2\r?\n}
    end
  end
end
