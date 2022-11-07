# frozen_string_literal: true

module DiscourseChatMatrix::MatrixReactionHandler
  def self.on_create(event)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])
    chat_message =
      ChatMessage.find_by(
        id:
          ChatMatrixEntity.select(:entity_id).where(
            entity_type: "ChatMessage",
            matrix_event_id: event[:content][:"m.relates_to"][:event_id],
          ),
      )

    emoji = event[:content][:"m.relates_to"][:key]

    Chat::ChatMessageReactor.new(chat_matrix_user.user, chat_message.chat_channel).react!(
      message_id: chat_message.id,
      react_action: Chat::ChatMessageReactor::ADD_REACTION,
      emoji: Emoji.unicode_replacements[emoji] || emoji,
    )
  end

  def self.on_delete(event)
    chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])
    chat_message_reaction =
      ChatMessageReaction.find_by(
        id:
          ChatMatrixEntity.select(:entity_id).where(
            entity_type: "ChatMessageReaction",
            matrix_event_id: event[:redacts],
          ),
      )
    chat_message = chat_message_reaction.chat_message

    Chat::ChatMessageReactor.new(chat_matrix_user.user, chat_message.chat_channel).react!(
      message_id: chat_message.id,
      react_action: Chat::ChatMessageReactor::REMOVE_REACTION,
      emoji: chat_message_reaction.emoji,
    )
  end
end
