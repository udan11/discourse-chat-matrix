# frozen_string_literal: true

module DiscourseChatMatrix::ChatMessageHandler
  def self.on_create(chat_message)
    # Skip this message if it was first posted in Matrix to avoid echo
    return if chat_message.instance_variable_get(:@from_matrix)

    api = DiscourseChatMatrix.api

    chat_matrix_user = ChatMatrixUser.ensure_exists_in_matrix!(chat_message.user, api)
    chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_matrix!(chat_message.chat_channel, api)

    ChatMatrixUser.ensure_in_chat_matrix_channel!(chat_matrix_user, chat_matrix_channel, api)

    cooked = ChatMessage.cook(chat_message.message, user_id: chat_message.last_editor_id)

    content = {
      msgtype: "m.text",
      body: chat_message.message,
      format: "org.matrix.custom.html",
      formatted_body: DiscourseChatMatrix::Message.process_cooked(cooked),
    }

    if chat_message.in_reply_to_id
      matrix_event_id =
        ChatMatrixEntity.where(
          entity_type: "ChatMessage",
          entity_id: chat_message.in_reply_to_id,
        ).pluck_first(:matrix_event_id)

      content[:"m.relates_to"] = {
        rel_type: "m.thread",
        event_id: matrix_event_id,
      } if matrix_event_id
    end

    response =
      api.send_message_event(
        chat_matrix_channel.matrix_room_id,
        "m.room.message",
        content,
        user_id: chat_matrix_user.matrix_user_id,
      )

    ChatMatrixEntity.create!(entity: chat_message, matrix_event_id: response[:event_id])

    # Ignore future events for this message to avoid echo
    DiscourseChatMatrix::MatrixEvents.ignore(response[:event_id])
  end

  def self.on_edit(chat_message)
    # Skip this message if it was first posted in Matrix to avoid echo
    return if chat_message.instance_variable_get(:@from_matrix)

    api = DiscourseChatMatrix.api

    chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_matrix!(chat_message.chat_channel, api)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_matrix!(chat_message.user, api)
    chat_matrix_entity = ChatMatrixEntity.find_by(entity: chat_message)

    cooked = ChatMessage.cook(chat_message.message, user_id: chat_message.last_editor_id)

    content = {
      msgtype: "m.text",
      body: chat_message.message,
      format: "org.matrix.custom.html",
      formatted_body: DiscourseChatMatrix::Message.process_cooked(cooked),
    }

    content = {
      **content,
      "m.new_content": content,
      "m.relates_to": {
        rel_type: "m.replace",
        event_id: chat_matrix_entity.matrix_event_id,
      },
    }

    response =
      api.send_message_event(
        chat_matrix_channel.matrix_room_id,
        "m.room.message",
        content,
        user_id: chat_matrix_user.matrix_user_id,
      )

    # Ignore future events for this message to avoid echo
    DiscourseChatMatrix::MatrixEvents.ignore(response[:event_id])
  end

  def self.on_delete(chat_message)
    api = DiscourseChatMatrix.api

    chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_matrix!(chat_message.chat_channel, api)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_matrix!(chat_message.user, api)
    chat_matrix_entity = ChatMatrixEntity.find_by(entity: chat_message)

    response =
      api.redact_event(
        chat_matrix_channel.matrix_room_id,
        chat_matrix_entity.matrix_event_id,
        user_id: chat_matrix_user.matrix_user_id,
      )

    # Ignore future events for this message to avoid echo
    DiscourseChatMatrix::MatrixEvents.ignore(response[:event_id])
  end
end
