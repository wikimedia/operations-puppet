# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'force merge of file' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'when run should not force' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'yaml',
          force => false,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"one": "bar"}',
        }
      MANIFEST
    end

    it 'applies manifest twice with stderr check' do
      expect(apply_manifest(pp, catch_failures: true).stderr).to match("Duplicate key 'one' found with values 'foo' and bar'. Use 'force' attribute to merge keys.")
      expect(apply_manifest(pp, catch_failures: true).stderr).to match("Duplicate key 'one' found with values 'foo' and bar'. Use 'force' attribute to merge keys.")
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match 'file exists'
      expect(file("#{basedir}/file").content).not_to match 'one: foo'
      expect(file("#{basedir}/file").content).not_to match 'one: bar'
    end
  end

  describe 'when run should not force by default' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'yaml',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"one": "bar"}',
        }
      MANIFEST
    end

    it 'applies manifest twice with stderr check' do
      expect(apply_manifest(pp, catch_failures: true).stderr).to match("Duplicate key 'one' found with values 'foo' and bar'. Use 'force' attribute to merge keys.")
      expect(apply_manifest(pp, catch_failures: true).stderr).to match("Duplicate key 'one' found with values 'foo' and bar'. Use 'force' attribute to merge keys.")
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match 'file exists'
      expect(file("#{basedir}/file").content).not_to match 'one: foo'
      expect(file("#{basedir}/file").content).not_to match 'one: bar'
    end
  end

  describe 'when run should force' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'yaml',
          force => true,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"one": "bar"}',
        }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match 'one: foo'
    end
  end

  describe 'when run should force merge nested arrays' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'json',
          force => true,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": [1]}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"one": [2]}',
        }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to contain '{"one":\[1,2\]}'
    end
  end

  describe 'when run should not force on plain' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          force => true,
          format => plain,
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"one": "bar"}',
        }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '{"one": "foo"}{"one": "bar"}'
    end
  end
end
