# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'format of file' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'when run should default to plain' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
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

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '{"one": "foo"}{"one": "bar"}'
    end
  end

  describe 'when run should output to plain format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
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

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '{"one": "foo"}{"one": "bar"}'
    end
  end

  describe 'when run should output to yaml format' do
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
          content => '{"two": "bar"}',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match 'one: foo\Rtwo: bar'
    end
  end

  describe 'when run should output yaml arrays to yaml format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'yaml',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => to_yaml([{ 'one.a' => 'foo', 'one.b' => 'bar' }]),
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => to_yaml([{ 'two.a' => 'dip', 'two.b' => 'doot' }]),
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '- one.a: foo\R  one.b: bar\R- two.a: dip\R  two.b: doot'
    end
  end

  describe 'when run should output to json format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'json',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"two": "bar"}',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '{"one":"foo","two":"bar"}'
    end
  end

  describe 'when run should output to json-array format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'json-array',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"two": "bar"}',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '[{"one":"foo"},{"two":"bar"}]'
    end
  end

  describe 'when run should output to json-pretty format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'json-pretty',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"two": "bar"}',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '{\R  "one": "foo",\R  "two": "bar"\R}'
    end
  end

  describe 'when run should output to json-array-pretty format' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          format => 'json-array-pretty',
        }

        concat::fragment { '1':
          target  => '#{basedir}/file',
          content => '{"one": "foo"}',
        }

        concat::fragment { '2':
          target  => '#{basedir}/file',
          content => '{"two": "bar"}',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match '[\n  {\n    "one": "foo"\n  },\n  {\n    "two": "bar"\n  }\n]'
    end
  end
end
