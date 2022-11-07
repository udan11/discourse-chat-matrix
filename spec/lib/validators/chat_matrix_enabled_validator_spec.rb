# frozen_string_literal: true

describe ChatMatrixEnabledValidator do
  describe "#valid_value?" do
    it "returns false if chat plugin is not installed or disabled" do
      # Given
      SiteSetting.chat_enabled = false
      SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"

      # Then
      expect(subject.valid_value?("f")).to eq(true)
      expect(subject.valid_value?("t")).to eq(false)
    end

    it "returns true if chat plugin is installed and enabled" do
      # Given
      SiteSetting.chat_enabled = true
      SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"

      # Then
      expect(subject.valid_value?("f")).to eq(true)
      expect(subject.valid_value?("t")).to eq(true)
    end

    it "returns false if matrix homeserver is unset" do
      # Given
      SiteSetting.chat_enabled = true
      SiteSetting.matrix_homeserver = ""

      # Then
      expect(subject.valid_value?("f")).to eq(true)
      expect(subject.valid_value?("t")).to eq(false)
    end

    it "returns true if matrix homeserver is set" do
      # Given
      SiteSetting.chat_enabled = true
      SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"

      # Then
      expect(subject.valid_value?("f")).to eq(true)
      expect(subject.valid_value?("t")).to eq(true)
    end
  end
end
