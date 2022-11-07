# frozen_string_literal: true

describe DiscourseChatMatrix::MatrixMessageHandler do
  fab!(:chat_matrix_user) { Fabricate(:chat_matrix_user) }
  fab!(:chat_matrix_channel) { Fabricate(:chat_matrix_channel) }

  before { DiscourseChatMatrixHelpers.enable! }

  describe "#on_create" do
    it "creates a new message" do
      # When
      DiscourseChatMatrix::MatrixEvents.call(
        age: 42,
        content: {
          body: "Hello world!",
          msgtype: "m.text",
        },
        event_id: "$xvFPyeUJDhurrCxemPRG5RBOiMra9z3OFr7ITopsVCg",
        origin_server_ts: 1_000_000_000_000,
        room_id: chat_matrix_channel.matrix_room_id,
        sender: chat_matrix_user.matrix_user_id,
        type: "m.room.message",
        unsigned: {
          age: 42,
        },
        user_id: chat_matrix_user.matrix_user_id,
      )

      # Then
      chat_message = ChatMessage.last
      expect(chat_message.user).to eq(chat_matrix_user.user)
      expect(chat_message.message).to eq("Hello world!")
    end
  end

  describe "#on_edit" do
    fab!(:chat_message) do
      Fabricate(:chat_message, user: chat_matrix_user.user, message: "Hello world!")
    end

    fab!(:chat_matrix_entity) do
      Fabricate(
        :chat_matrix_entity,
        entity: chat_message,
        matrix_event_id: "$C8BHglcsRUqbhnaoTW2cAgyzGu4Yy4jOHPNAaqOEaW",
      )
    end

    it "edits an existing message" do
      # When
      DiscourseChatMatrix::MatrixEvents.call(
        age: 42,
        content: {
          body: "Good bye!",
          "m.new_content": {
            body: "Good bye!",
            msgtype: "m.text",
          },
          "m.relates_to": {
            event_id: "$C8BHglcsRUqbhnaoTW2cAgyzGu4Yy4jOHPNAaqOEaW",
            rel_type: "m.replace",
          },
          msgtype: "m.text",
        },
        event_id: "$rFV2QtYzsyR2wB8Oh_M5LESrHl4K_3_z-SeMhfj5hTI",
        origin_server_ts: 1_000_000_000_000,
        room_id: chat_matrix_channel.matrix_room_id,
        sender: chat_matrix_user.matrix_user_id,
        type: "m.room.message",
        unsigned: {
          age: 42,
        },
        user_id: chat_matrix_user.matrix_user_id,
      )

      # Then
      expect(chat_message.reload.message).to eq("Good bye!")
    end
  end

  describe "#on_destroy" do
    fab!(:chat_message) do
      Fabricate(:chat_message, user: chat_matrix_user.user, message: "Hello world!")
    end

    fab!(:chat_matrix_entity) do
      Fabricate(
        :chat_matrix_entity,
        entity: chat_message,
        matrix_event_id: "$WCChmBD9g7DzHXavd0DuAFrYU3MHYC61waem832ZsA",
      )
    end

    it "destroys an existing message" do
      # When
      DiscourseChatMatrix::MatrixEvents.call(
        age: 42,
        content: {
          reason: "Spam",
        },
        event_id: "$EqhkBTXGJtPPJ1-QfSl0l5TToDG4TkIeylrCzodr2pY",
        origin_server_ts: 1_000_000_000_000,
        redacts: "$WCChmBD9g7DzHXavd0DuAFrYU3MHYC61waem832ZsA",
        room_id: chat_matrix_channel.matrix_room_id,
        sender: chat_matrix_user.matrix_user_id,
        type: "m.room.redaction",
        unsigned: {
          age: 42,
        },
        user_id: chat_matrix_user.matrix_user_id,
      )

      # Then
      expect { chat_message.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
