# frozen_string_literal: true

module DiscourseChatMatrixHelpers
  def self.enable!
    Discourse.redis.flushdb

    SiteSetting.chat_enabled = true
    SiteSetting.matrix_homeserver = "https://homeserver.discourse.org"
    SiteSetting.matrix_server_name = "matrix.discourse.org"
    SiteSetting.discourse_chat_matrix_enabled = true
  end
end

RSpec.configure { |config| config.include DiscourseChatMatrixHelpers }
