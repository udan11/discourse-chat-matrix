# frozen_string_literal: true

module DiscourseChatMatrix::MatrixMessageHandler
  def self.on_create(event)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])
    chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_chat!(event[:room_id])
    in_reply_to_id =
      if event[:content][:"m.relates_to"].present?
        ChatMatrixEntity.where(
          matrix_event_id: event[:content][:"m.relates_to"][:event_id],
        ).pluck_first(:chat_message_id)
      end

    creator =
      Chat::ChatMessageCreator.new(
        chat_channel: chat_matrix_channel.chat_channel,
        in_reply_to_id: in_reply_to_id,
        user: chat_matrix_user.user,
        content: event[:content][:body],
      )
    creator.chat_message.instance_variable_set(:@from_matrix, true) # TODO
    creator.create

    ChatMatrixEntity.create!(entity: creator.chat_message, matrix_event_id: event[:event_id])

    # TODO: This should be a part of `Chat::ChatMessageCreator`.
    if chat_matrix_channel.chat_channel.direct_message_channel?
      user_ids_allowing_communication =
        UserCommScreener.new(
          acting_user: chat_matrix_user.user,
          target_user_ids:
            chat_matrix_channel.chat_channel.user_chat_channel_memberships.pluck(:user_id),
        ).allowing_actor_communication

      if user_ids_allowing_communication.any?
        chat_matrix_channel
          .chat_channel
          .user_chat_channel_memberships
          .where(user_id: user_ids_allowing_communication)
          .update_all(following: true)
      end
    end
  end

  def self.on_edit(event)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])
    chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_chat!(event[:room_id])

    chat_message =
      ChatMessage.find_by(
        id:
          ChatMatrixEntity.select(:entity_id).where(
            entity_type: "ChatMessage",
            matrix_event_id: event[:content][:"m.relates_to"][:event_id],
          ),
      )

    chat_message.instance_variable_set(:@from_matrix, true) # TODO
    chat_message_updater =
      Chat::ChatMessageUpdater.update(
        guardian: chat_matrix_user.user.guardian,
        chat_message: chat_message,
        new_content: event[:content][:"m.new_content"][:body],
        upload_ids: [],
      )

    if chat_message_updater.failed?
      Rails.logger.error(
        "Failed to update #{chat_message.id}: #{chat_message_updater.error}. event = #{event.to_json}",
      )
    end
  end

  def self.on_delete(event)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])
    user = chat_matrix_user.user
    guardian = user.guardian

    chat_message =
      ChatMessage.find_by(
        id:
          ChatMatrixEntity.select(:entity_id).where(
            entity_type: "ChatMessage",
            matrix_event_id: event[:redacts],
          ),
      )
    chat_channel = chat_message.chat_channel
    chatable = chat_channel.chatable

    if guardian.can_delete_chat?(chat_message, chatable)
      ChatPublisher.publish_delete!(chat_channel, chat_message) if chat_message.trash!(user)
    end
  end
end
