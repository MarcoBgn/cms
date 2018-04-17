describe Cms::FormBuilder do
  let(:template) { ActionView::Base.new }
  let(:identifier) { 'identifier' }
  let(:content) { 'content' }
  let(:block_attributes) { { identifier: identifier, content: content } }

  before { template.instance_variable_set('@blocks_attributes', [block_attributes]) }

  subject do
    described_class.new(:model, block_attributes, template, {})
  end

  describe '#page_image' do
    let(:page) { Comfy::Cms::Page.new }
    let(:tag) do
      ComfortableMexicanSofa::Tag::PageImage.new.tap do |pi|
        pi.blockable = page
        pi.identifier = identifier
      end
    end

    it 'adds label' do
      expect(subject.page_image(tag, 0)).to match(/label.*#{identifier.capitalize}.*label/)
    end

    it 'adds text input' do
      expect(subject.page_image(tag, 0)).to match(/input.*text/)
    end

    it 'adds hidden input' do
      expect(subject.page_image(tag, 0)).to match(/input.*hidden/)
    end

    it 'adds previewer' do
      expect(subject.page_image(tag, 0)).to match(/div.*preview.*div/)
    end

    it 'adds insert button' do
      expect(subject.page_image(tag, 0)).to match(/button[\s\S]*insert-image[\s\S.]*button/)
    end

    it 'adds remove button' do
      expect(subject.page_image(tag, 0)).to match(/button.*Remove.*button/)
    end
  end

  describe '#collection_check_boxes' do
    let(:identifier) { 'topics' }
    let(:page) { Comfy::Cms::Page.new }
    let(:tag) do
      ComfortableMexicanSofa::Tag::CollectionCheckBoxes.new.tap do |pi|
        pi.blockable = page
        pi.identifier = identifier
        pi.params = ['param1, param2']
      end
    end

    it 'adds labels for each checkbox' do
      expect(subject.collection_check_boxes(tag, 0)).to match(/label.*>param1<.*label/)
      expect(subject.collection_check_boxes(tag, 0)).to match(/label.*>param2<.*label/)
    end

    it 'adds checkbox input' do
      expect(subject.collection_check_boxes(tag, 0)).to match(/input.*checkbox/)
    end

    it 'adds hidden input for identifier' do
      expect(subject.collection_check_boxes(tag, 0)).to match(/input.*hidden.*topics/)
    end
  end
end
