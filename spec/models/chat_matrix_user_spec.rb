# frozen_string_literal: true

describe ChatMatrixUser do
  describe "#ensure_exists_in_matrix!" do
    fab!(:user) { Fabricate(:user, username: "foobar") }
    let(:api) { DiscourseChatMatrix.api }

    before do
      SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"
      SiteSetting.matrix_server_name = "matrix.discourse.org"
    end

    it "calls register and saves association" do
      # Given
      api.expects(:register).with(type: "m.login.application_service", username: "foobar-d").once

      api.expects(:set_display_name).with(
        "@foobar-d:matrix.discourse.org",
        "foobar",
        user_id: "@foobar-d:matrix.discourse.org",
      )

      # When
      described_class.ensure_exists_in_matrix!(user, api)

      # Then
      chat_matrix_user = described_class.last
      expect(chat_matrix_user.user).to eq(user)
      expect(chat_matrix_user.matrix_user_id).to eq("@foobar-d:matrix.discourse.org")
    end
  end

  describe "#ensure_exists_in_chat!" do
    it "creates a new staged user and saves association" do
      # When
      described_class.ensure_exists_in_chat!("@foobar:matrix.discourse.org")

      # Then
      chat_matrix_user = described_class.last
      expect(chat_matrix_user.user.username).to eq("foobar-m")
      expect(chat_matrix_user.user.staged).to eq(true)
      expect(chat_matrix_user.matrix_user_id).to eq("@foobar:matrix.discourse.org")
    end
  end
end
