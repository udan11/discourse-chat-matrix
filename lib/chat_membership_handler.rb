# frozen_string_literal: true

module DiscourseChatMatrix::ChatMembershipHandler
  def self.on_change(user, chat_channel, membership)
    api = DiscourseChatMatrix.api

    if membership
      chat_matrix_channel = ChatMatrixChannel.ensure_exists_in_matrix!(chat_channel, api)
      chat_matrix_user = ChatMatrixUser.ensure_exists_in_matrix!(user, api)

      begin
        api.join_room(chat_matrix_channel.matrix_room_id, user_id: chat_matrix_user.matrix_user_id)
      rescue StandardError
        nil
      end
    else
      chat_matrix_channel = ChatMatrixChannel.find_by(chat_channel: chat_channel)
      chat_matrix_user = ChatMatrixUser.find_by(user: user)

      if chat_matrix_channel && chat_matrix_user
        begin
          api.leave_room(
            chat_matrix_channel.matrix_room_id,
            user_id: chat_matrix_user.matrix_user_id,
          )
        rescue StandardError
          nil
        end
      end
    end
  end
end
