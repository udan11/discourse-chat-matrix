# frozen_string_literal: true

describe DiscourseChatMatrix::Message do
  let(:cooked) { PrettyText.cook("Hello! :wave:") }

  describe "#process_cooked" do
    it "converts emojis from Unicode to Discourse text" do
      expect(described_class.process_cooked(cooked)).to eq("<p>Hello! 👋</p>")
    end
  end
end
