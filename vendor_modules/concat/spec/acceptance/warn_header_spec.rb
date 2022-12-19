# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat warn_header =>' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'applies the manifest twice with no stderr' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        warn  => true,
      }

      concat::fragment { '1':
        target  => '#{basedir}/file',
        content => '1',
        order   => '01',
      }

      concat::fragment { '2':
        target  => '#{basedir}/file',
        content => '2',
        order   => '02',
      }

      concat { '#{basedir}/file2':
        warn  => false,
      }

      concat::fragment { 'file2_1':
        target  => '#{basedir}/file2',
        content => '1',
        order   => '01',
      }

      concat::fragment { 'file2_2':
        target  => '#{basedir}/file2',
        content => '2',
        order   => '02',
      }

      concat { '#{basedir}/file3':
        warn  => "# foo\n",
      }

      concat::fragment { 'file3_1':
        target  => '#{basedir}/file3',
        content => '1',
        order   => '01',
      }

      concat::fragment { 'file3_2':
        target  => '#{basedir}/file3',
        content => '2',
        order   => '02',
      }

    MANIFEST
    end

    it 'when true should enable default warning message' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match %r{# This file is managed by Puppet\. DO NOT EDIT\.}
      expect(file("#{basedir}/file").content).to match %r{1}
      expect(file("#{basedir}/file").content).to match %r{2}
    end

    it 'when false should not enable default warning message' do
      expect(file("#{basedir}/file2")).to be_file
      expect(file("#{basedir}/file2").content).not_to match %r{# This file is managed by Puppet\. DO NOT EDIT\.}
      expect(file("#{basedir}/file2").content).to match %r{1}
      expect(file("#{basedir}/file2").content).to match %r{2}
    end

    it 'when foo should overide default warning message' do
      expect(file("#{basedir}/file3")).to be_file
      expect(file("#{basedir}/file3").content).to match %r{# foo}
      expect(file("#{basedir}/file3").content).to match %r{1}
      expect(file("#{basedir}/file3").content).to match %r{2}
    end
  end
end
