# frozen_string_literal: true

describe DiscourseChatMatrix::MatrixMessageHandler do
  fab!(:chat_matrix_user) { Fabricate(:chat_matrix_user) }
  fab!(:chat_matrix_channel) { Fabricate(:chat_matrix_channel) }

  fab!(:chat_message) do
    Fabricate(:chat_message, user: chat_matrix_user.user, message: "Hello world!")
  end

  fab!(:chat_matrix_entity) do
    Fabricate(
      :chat_matrix_entity,
      entity: chat_message,
      matrix_event_id: "$sABHP9oZsHj-meykww5JYaSBr0PZ5v0nVgXvCKz8wMA",
    )
  end

  before { DiscourseChatMatrixHelpers.enable! }

  describe "#on_create" do
    it "creates a new reaction" do
      # When
      DiscourseChatMatrix::MatrixEvents.call(
        age: 42,
        content: {
          "m.relates_to": {
            event_id: "$sABHP9oZsHj-meykww5JYaSBr0PZ5v0nVgXvCKz8wMA",
            key: "😀",
            rel_type: "m.annotation",
          },
        },
        event_id: "$NC3dGdL5GPhwvDKlkQ0tW_NhX9d9pf23ff4JM_qYwls",
        origin_server_ts: 1_000_000_000_000,
        room_id: chat_matrix_channel.matrix_room_id,
        sender: chat_matrix_user.matrix_user_id,
        type: "m.reaction",
        unsigned: {
          age: 42,
        },
        user_id: chat_matrix_user.matrix_user_id,
      )

      # Then
      chat_message_reaction = ChatMessageReaction.last
      expect(chat_message_reaction.chat_message).to eq(chat_message)
      expect(chat_message_reaction.user).to eq(chat_matrix_user.user)
      expect(chat_message_reaction.emoji).to eq("grinning")
    end
  end

  describe "#on_destroy" do
    fab!(:chat_message_reaction) do
      Fabricate(
        :chat_message_reaction,
        chat_message: chat_message,
        user: chat_matrix_user.user,
        emoji: "grinning",
      )
    end

    fab!(:chat_message_reaction_matrix_entity) do
      Fabricate(
        :chat_matrix_entity,
        entity: chat_message_reaction,
        matrix_event_id: "$wSUdMgmcPLVNcLS27BTNYxk7aJ3JjeudOmuAPNpl4f0",
      )
    end

    it "destroys a reaction" do
      # When
      DiscourseChatMatrix::MatrixEvents.call(
        age: 42,
        content: {
        },
        event_id: "$DNNYK8mfJwe4wydBj29nZn1sfe17CKsvORWPNXYIOvI",
        origin_server_ts: 1_000_000_000_000,
        redacts: "$wSUdMgmcPLVNcLS27BTNYxk7aJ3JjeudOmuAPNpl4f0",
        room_id: chat_matrix_channel.matrix_room_id,
        sender: chat_matrix_user.matrix_user_id,
        type: "m.room.redaction",
        unsigned: {
          age: 42,
        },
        user_id: chat_matrix_user.matrix_user_id,
      )

      # Then
      expect { chat_message_reaction.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
