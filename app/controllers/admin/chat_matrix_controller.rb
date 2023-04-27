# frozen_string_literal: true

class DiscourseChatMatrix::AdminChatMatrixController < Admin::AdminController
  requires_plugin DiscourseChatMatrix::PLUGIN_NAME

  def index
    render json: { synapse_config: synapse_config }
  end

  def regenerate_tokens
    SiteSetting.matrix_as_token = SecureRandom.hex(32)
    SiteSetting.matrix_hs_token = SecureRandom.hex(32)

    render json: { synapse_config: synapse_config }
  end

  private

  def synapse_config
    user_regex =
      Regexp.escape(
        SiteSetting
          .matrix_user_id
          .gsub("{server_name}", DiscourseChatMatrix.server_name)
        ).gsub("\\{user\\}", ".*")

    alias_regex =
      Regexp.escape(
        SiteSetting
          .matrix_room_alias
          .gsub("{server_name}", DiscourseChatMatrix.server_name)
        ).gsub("\\{room\\}", ".*")

    <<~CONFIG
      id: "Discourse Chat Bridge"
      url: "#{Discourse.base_url}/matrix"
      as_token: "#{SiteSetting.matrix_as_token}"
      hs_token: "#{SiteSetting.matrix_hs_token}"
      sender_localpart: "_discourse"
      namespaces:
        users:
          - exclusive: true
            regex: '#{user_regex}'
        aliases:
          - exclusive: false
            regex: '#{alias_regex}'
        rooms: []
    CONFIG
  end
end
