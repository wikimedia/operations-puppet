# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'symbolic name' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  let(:pp) do
    <<-MANIFEST
      concat { 'not_abs_path':
        path => '#{basedir}/file',
      }

      concat::fragment { '1':
        target  => 'not_abs_path',
        content => '1',
        order   => '01',
      }

      concat::fragment { '2':
        target  => 'not_abs_path',
        content => '2',
        order   => '02',
      }
    MANIFEST
  end

  it 'applies the manifest twice with no stderr' do
    idempotent_apply(pp)
    expect(file("#{basedir}/file")).to be_file
    expect(file("#{basedir}/file").content).to match '1'
    expect(file("#{basedir}/file").content).to match '2'
  end
end
