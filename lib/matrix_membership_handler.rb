# frozen_string_literal: true

module DiscourseChatMatrix::MatrixMembershipHandler
  def self.on_change(event)
    # We are aware what the bot does, so we can ignore it
    return if event[:sender] == DiscourseChatMatrix.bot_user_id

    case event[:content][:membership]
    when "invite", "join"
      chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_chat!(event[:room_id], event)
      chat_matrix_user = ChatMatrixUser.ensure_exists_in_chat!(event[:user_id])

      if event[:content][:membership] == "invite"
        # TODO: Check if 'invite' must be replied with 'join'
        DiscourseChatMatrix.api.join_room(event[:room_id], user_id: event[:state_key])
      end

      chat_matrix_channel.chat_channel.add(chat_matrix_user.user)
    when "leave"
      chat_matrix_channel = ChatMatrixChannel.find_by(matrix_room_id: event[:room_id])
      chat_matrix_user = ChatMatrixUser.find_by(matrix_user_id: event[:user_id])

      if chat_matrix_channel && chat_matrix_user
        chat_matrix_channel.chat_channel.remove(chat_matrix_user.user)
      end
    end
  end
end
