require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::resource::dump_params' do
  it 'exists' do
    is_expected.not_to be_nil
  end

  describe 'mock resource' do
    before do
      allow(scope).to receive(:resource).and_return({foo: 'foo', bar: 'bar'})
    end
    it 'convert symbols to strings' do
      is_expected.to run.and_return({'foo' => 'foo', 'bar' => 'bar'})
    end
  end
end
