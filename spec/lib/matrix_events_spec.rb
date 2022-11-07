# frozen_string_literal: true

describe DiscourseChatMatrix::MatrixEvents do
  before do
    @old_handlers = described_class.instance_variable_get(:@handlers)
    described_class.reset_handlers!
  end

  after do
    described_class.instance_variable_set(:@handlers, @old_handlers)
  end

  describe "#handlers" do
    it "returns an empty array when no event was set" do
      # Then
      expect(described_class.handlers("m.room.message")).to eq([])
    end

    it "returns an array of handlers when an event was set" do
      # Given
      described_class.on("m.room.message") { |event| nil }

      # Then
      expect(described_class.handlers("m.room.message").size).to eq(1)
    end
  end

  describe "#on" do
    it "registers an event handler" do
      # When
      described_class.on("m.room.message") { |event| nil }

      # Then
      expect(described_class.handlers("m.room.message").size).to eq(1)
    end
  end

  describe "#call" do
    it "registers an event handler" do
      # Given
      called = 0
      described_class.on("m.room.message") { |event| called += 1 }

      # When
      described_class.call({ type: "m.room.message" })

      # Then
      expect(called).to eq(1)
    end
  end

  describe "#ignore and #ignored?" do
    before { Discourse.redis.flushdb }
    after { Discourse.redis.flushdb }

    it "sets and returns ignored flag" do
      # When
      described_class.ignore("foo")

      # Then
      expect(described_class.ignored?("foo")).to eq(true)
    end

    it "does not return if not set" do
      expect(described_class.ignored?("foo")).to eq(false)
    end
  end
end
