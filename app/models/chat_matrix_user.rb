# frozen_string_literal: true

class ChatMatrixUser < ActiveRecord::Base
  belongs_to :user

  def self.ensure_exists_in_matrix!(user, api)
    chat_matrix_user = find_by(user: user)
    return chat_matrix_user if chat_matrix_user

    matrix_user_id =
      SiteSetting
        .matrix_user_id
        .gsub("{user}", user.username)
        .gsub("{server_name}", DiscourseChatMatrix.server_name)

    begin
      api.register(
        type: "m.login.application_service",
        username: ::DiscourseChatMatrix.localpart(matrix_user_id),
      )
    rescue MatrixSdk::MatrixRequestError => e
      raise if e.code != "M_USER_IN_USE"
    end

    # Sync user display name and avatar
    api.set_display_name(matrix_user_id, user.username, user_id: matrix_user_id)

    create!(user: user, matrix_user_id: matrix_user_id)
  end

  def self.ensure_exists_in_chat!(matrix_user_id)
    chat_matrix_user = find_by(matrix_user_id: matrix_user_id)
    return chat_matrix_user if chat_matrix_user

    username =
      SiteSetting.chat_username.gsub("{user}", DiscourseChatMatrix.localpart(matrix_user_id))
    username = UserNameSuggester.suggest(username)

    user = User.create!(username: username, email: "#{username}@matrix", staged: true)

    create!(user: user, matrix_user_id: matrix_user_id)
  end

  def self.ensure_in_chat_matrix_channel!(chat_matrix_user, chat_matrix_channel, api)
    #  if client /join:
    #      SUCCESS
    #  else if bot /invite client:
    #      if client /join:
    #          SUCCESS
    #      else:
    #          FAIL (client couldn't join)
    #  else if bot /join:
    #      if bot /invite client and client /join:
    #          SUCCESS
    #      else:
    #          FAIL (bot couldn't invite)
    #  else:
    #      FAIL (bot can't get into the room)

    begin
      api.join_room(chat_matrix_channel.matrix_room_id, user_id: chat_matrix_user.matrix_user_id)
    rescue MatrixSdk::MatrixRequestError => e
      raise if e.code != "M_FORBIDDEN"

      begin
        api.invite_user(chat_matrix_channel.matrix_room_id, chat_matrix_user.matrix_user_id)
        api.join_room(chat_matrix_channel.matrix_room_id)
      rescue MatrixSdk::MatrixRequestError => e
        api.join_room(chat_matrix_channel.matrix_room_id)
        api.invite_user(chat_matrix_channel.matrix_room_id, chat_matrix_user.matrix_user_id)
        api.join_room(chat_matrix_channel.matrix_room_id, user_id: chat_matrix_user.matrix_user_id)
      end
    end
  end
end

# == Schema Information
#
# Table name: chat_matrix_users
#
#  id             :bigint           not null, primary key
#  user_id        :bigint
#  matrix_user_id :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
