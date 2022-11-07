# frozen_string_literal: true

class ChatMatrixChannel < ActiveRecord::Base
  belongs_to :chat_channel

  def self.ensure_exists_in_matrix!(chat_channel, api)
    chat_matrix_channel = find_by(chat_channel: chat_channel)
    return chat_matrix_channel if chat_matrix_channel

    matrix_room_name =
      if chat_channel.name.present?
        chat_channel.name
      elsif chat_channel.direct_message_channel?
        User.where(id: chat_channel.allowed_user_ids).pluck(:username).join(", ")
      else
        "Chat #{chat_channel.id}"
      end

    matrix_room_alias =
      begin
        room =
          if chat_channel.name.present?
            chat_channel.name.strip.downcase.gsub(/(\s|_)+/, "-")
          else
            "chat-#{chat_channel.id}"
          end

        SiteSetting
          .matrix_room_alias
          .gsub("{room}", room)
          .gsub("{server_name}", DiscourseChatMatrix.server_name)
      end

    room_visibility =
      if chat_channel.direct_message_channel?
        "private"
      elsif Category === chat_channel.chatable && chat_channel.chatable.read_restricted?
        "private"
      else
        "public"
      end

    begin
      response =
        api.create_room(
          name: matrix_room_name,
          room_alias: DiscourseChatMatrix.localpart(matrix_room_alias),
          is_direct: chat_channel.direct_message_channel?,
          visibility: room_visibility,
        )
      matrix_room_id = response[:room_id]
      # TODO: The event for room creation and join room may be received before
      # the response from create_room is returned. It is difficult to handle
      # this case because there is no information that can be used to reference
      # the room. At this moment, it is not a problem because the event will be
      # resent by Matrix server and processed again after the room is created.
    rescue MatrixSdk::MatrixRequestError => e
      # TODO: If M_ROOM_IN_USE, create a different room or try to find room_id
      puts "Failed to create room #{matrix_room_name}: #{e.message} (#{e.code})"
      raise
    end

    # Invite users to private room
    if chat_channel.direct_message_channel?
      User
        .where(id: chat_channel.allowed_user_ids)
        .find_each do |user|
          begin
            invited_user = ChatMatrixUser.ensure_exists_in_matrix!(user, api)
            api.invite_user(matrix_room_id, invited_user.matrix_user_id)
          rescue MatrixSdk::MatrixRequestError => e
            raise if e.code != "M_FORBIDDEN"
          end
        end
    end

    create!(
      chat_channel: chat_channel,
      matrix_room_id: matrix_room_id,
      matrix_room_alias: matrix_room_alias,
    )
  end

  def self.ensure_exists_in_chat!(matrix_room_id, event = nil)
    chat_matrix_channel = find_by(matrix_room_id: matrix_room_id)
    return chat_matrix_channel if chat_matrix_channel

    if event.dig(:content, :is_direct)
      creator = ChatMatrixUser.find_by(matrix_user_id: event[:user_id])&.user
      user = ChatMatrixUser.find_by(matrix_user_id: event[:state_key])&.user

      chat_channel =
        Chat::DirectMessageChannelCreator.create!(
          acting_user: creator,
          target_users: [creator, user].compact,
        )

      # There are no aliases for private rooms
      matrix_room_alias = nil
    else
      category = nil
      room_alias = nil
      room_name = nil
      room_description = nil
      users = []

      event[:invite_room_state].each do |state|
        case state[:type]
        when "m.room.join_rules"
          category =
            if state.dig(:content, :join_rule) == "private"
              Category.find_by(id: SiteSetting.staff_category_id)
            else
              Category.find_by(id: SiteSetting.uncategorized_category_id)
            end
        when "m.room.canonical_alias"
          room_alias = state.dig(:content, :alias)
        when "m.room.name"
          room_name = state.dig(:content, :name)
        when "m.room.topic"
          room_description = state.dig(:content, :topic)
        when "m.room.member"
          users << ChatMatrixUser.find_by(matrix_user_id: state[:state_key])&.user
        end
      end

      chat_channel = category.create_chat_channel!(name: room_name, description: room_description)

      users.each { |u| chat_channel.add(u) }
    end

    create!(
      chat_channel: chat_channel,
      matrix_room_id: matrix_room_id,
      matrix_room_alias: room_alias,
    )
  end
end

# == Schema Information
#
# Table name: chat_matrix_channels
#
#  id                :bigint           not null, primary key
#  chat_channel_id   :bigint
#  matrix_room_id    :string
#  matrix_room_alias :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
