# frozen_string_literal: true

describe ChatMatrixChannel do
  describe "#ensure_exists_in_matrix!" do
    fab!(:chat_channel) { Fabricate(:chat_channel, name: "General") }

    let(:api) { DiscourseChatMatrix.api }

    before do
      SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"
      SiteSetting.matrix_server_name = "matrix.discourse.org"
    end

    it "calls create_room and saves association" do
      # Given
      api
        .expects(:create_room)
        .with(name: "General", room_alias: "general-d", is_direct: false, visibility: "public")
        .returns(room_id: "!foobar:matrix.discourse.org")
        .once

      # When
      described_class.ensure_exists_in_matrix!(chat_channel, api)

      # Then
      chat_matrix_channel = described_class.last
      expect(chat_matrix_channel.chat_channel).to eq(chat_channel)
      expect(chat_matrix_channel.matrix_room_id).to eq("!foobar:matrix.discourse.org")
      expect(chat_matrix_channel.matrix_room_alias).to eq("#general-d:matrix.discourse.org")
    end
  end

  describe "#ensure_exists_in_chat!" do
    it "creates a new room" do
      # TODO
    end
  end
end
