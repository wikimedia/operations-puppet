require 'spec_helper'

resource_class = Puppet::Type.type(:scap_source)

describe resource_class do
  describe 'when validating attributes' do
    [:scap_repository, :origin, :owner, :group, :base_path].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [:ensure, :repository].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  context "Default values" do
    subject do
      resource_class.new(:name => 'test/deploy')
    end

    it "name variable should be test/deploy" do
      expect(subject.name).to eq('test/deploy')
    end

    it "owner/group should be trebuchet/wikidev" do
      expect(subject[:owner]).to eq('trebuchet')
      expect(subject[:group]).to eq('wikidev')
    end

    it "repository should be equal to the title" do
      expect(subject[:repository]).to eq('test/deploy')
      expect(subject[:scap_repository]).to eq(false)
    end

    it "origin should be gerrit" do
      expect(subject[:origin]).to eq(:gerrit)
    end

    it "base_path should be /srv/deployment" do
      expect(subject[:base_path]).to eq('/srv/deployment')
    end
  end
end
