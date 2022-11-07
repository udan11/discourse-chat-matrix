# frozen_string_literal: true

# name: discourse-chat-matrix
# about: Integrate Discourse Chat with Matrix
# version: 0.0.1
# authors: Dan Ungureanu
# url: https://meta.discourse.org/t/TODO

require "net/http"
require "uri"

gem "little-plugger", "1.1.4"
gem "logging", "2.3.1"
gem "matrix_sdk", "2.8.0"

enabled_site_setting :discourse_chat_matrix_enabled

require_relative "lib/validators/chat_matrix_enabled_validator.rb"

register_asset "stylesheets/common/chat-matrix.scss"

after_initialize do
  module ::DiscourseChatMatrix
    PLUGIN_NAME = "discourse-chat-matrix"

    def self.server_name
      SiteSetting.matrix_server_name.presence || URI(SiteSetting.matrix_homeserver).hostname
    end

    def self.localpart(full_name)
      full_name.split(":").first[1..]
    end

    def self.bot_user_id
      "@_discourse:#{DiscourseChatMatrix.server_name}"
    end

    def self.api
      @api ||=
        MatrixSdk::Api.new(
          SiteSetting.matrix_homeserver,
          protocols: %i[AS CS],
          access_token: SiteSetting.matrix_as_token,
          autoretry: false,
        )
    end

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseChatMatrix
    end

    DiscourseChatMatrix::Engine.routes.draw do
      get "/_matrix/app/v1/users/:id" => "chat_matrix#on_get_users"
      get "/_matrix/app/v1/rooms/:alias" => "chat_matrix#on_get_room_alias"
      put "/_matrix/app/v1/transactions/:id" => "chat_matrix#on_transaction"

      get "/users/:id" => "chat_matrix#on_get_users"
      get "/rooms/:alias" => "chat_matrix#on_get_room_alias"
      put "/transactions/:id" => "chat_matrix#on_transaction"

      get "/health" => "chat_matrix#on_health_check"
    end

    Discourse::Application.routes.prepend do
      get "/.well-known/matrix/client" => "discourse_chat_matrix/chat_matrix#well_known"
      get "/admin/plugins/matrix" => "discourse_chat_matrix/admin_chat_matrix#index"
      post "/admin/plugins/matrix/tokens" =>
             "discourse_chat_matrix/admin_chat_matrix#regenerate_tokens"

      mount DiscourseChatMatrix::Engine, at: "/matrix"
    end
  end

  require_relative "app/controllers/admin/chat_matrix_controller.rb"
  require_relative "app/controllers/chat_matrix_controller.rb"
  require_relative "app/models/chat_matrix_channel.rb"
  require_relative "app/models/chat_matrix_entity.rb"
  require_relative "app/models/chat_matrix_user.rb"
  require_relative "lib/chat_membership_handler.rb"
  require_relative "lib/chat_message_handler.rb"
  require_relative "lib/matrix_events.rb"
  require_relative "lib/matrix_membership_handler.rb"
  require_relative "lib/matrix_message_handler.rb"
  require_relative "lib/matrix_reaction_handler.rb"
  require_relative "lib/message.rb"

  add_admin_route "chat_matrix.title", "matrix"

  # -------------------
  # Discourse -> Matrix
  # -------------------

  # Handle messages
  on(:chat_message_created) do |chat_message, chat_channel, user|
    DiscourseChatMatrix::ChatMessageHandler.on_create(chat_message)
  end

  on(:chat_message_edited) do |chat_message, chat_channel, user|
    DiscourseChatMatrix::ChatMessageHandler.on_edit(chat_message)
  end

  on(:chat_message_deleted) do |chat_message, chat_channel, user|
    DiscourseChatMatrix::ChatMessageHandler.on_delete(chat_message)
  end

  # Handle chat channel membership changes
  on(:chat_membership) do |user, chat_channel, membership|
    DiscourseChatMatrix::ChatMembershipHandler.on_change(user, chat_channel, membership)
  end

  # -------------------
  # Matrix -> Discourse
  # -------------------

  # Handle new / edited messages
  DiscourseChatMatrix::MatrixEvents.on("m.room.message") do |event|
    if event.dig(:content, :msgtype) == "m.text"
      if event.dig(:content, :"m.new_content").present?
        if event.dig(:content, :"m.relates_to", :rel_type) == "m.replace"
          DiscourseChatMatrix::MatrixMessageHandler.on_edit(event)
        else
          Rails.logger.warn("Unknown relationship type: #{event}")
        end
      else
        DiscourseChatMatrix::MatrixMessageHandler.on_create(event)
      end
    end
  end

  # Handle deleted messages
  DiscourseChatMatrix::MatrixEvents.on("m.room.redaction") do |event|
    chat_matrix_entity = ChatMatrixEntity.find_by(matrix_event_id: event[:redacts])

    case chat_matrix_entity.entity_type
    when "ChatMessage"
      DiscourseChatMatrix::MatrixMessageHandler.on_delete(event)
    when "ChatMessageReaction"
      DiscourseChatMatrix::MatrixReactionHandler.on_delete(event)
    end
  end

  # Handle room membership changes
  DiscourseChatMatrix::MatrixEvents.on("m.room.member") do |event|
    DiscourseChatMatrix::MatrixMembershipHandler.on_change(event)
  end

  # Handle new reactions
  DiscourseChatMatrix::MatrixEvents.on("m.reaction") do |event|
    DiscourseChatMatrix::MatrixReactionHandler.on_create(event)
  end
end
