require 'spec_helper'

describe 'loadyaml' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /wrong number of arguments/i) }

  context 'when a non-existing file is specified' do
    let(:filename) { '/tmp/doesnotexist' }
    before {
      File.expects(:exists?).with(filename).returns(false).once
      YAML.expects(:load_file).never
    }
    it { is_expected.to run.with_params(filename, {'default' => 'value'}).and_return({'default' => 'value'}) }
  end

  context 'when an existing file is specified' do
    let(:filename) { '/tmp/doesexist' }
    let(:data) { { 'key' => 'value' } }
    before {
      File.expects(:exists?).with(filename).returns(true).once
      YAML.expects(:load_file).with(filename).returns(data).once
    }
    it { is_expected.to run.with_params(filename).and_return(data) }
  end

  context 'when the file could not be parsed' do
    let(:filename) { '/tmp/doesexist' }
    before {
      File.expects(:exists?).with(filename).returns(true).once
      YAML.stubs(:load_file).with(filename).once.raises StandardError, 'Something terrible have happened!'
    }
    it { is_expected.to run.with_params(filename, {'default' => 'value'}).and_return({'default' => 'value'}) }
  end
end
