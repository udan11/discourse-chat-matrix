# frozen_string_literal: true

class ChatMatrixEnabledValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    return true if val == "f"

    return false if !SiteSetting.respond_to?(:chat_enabled) || !SiteSetting.chat_enabled
    return false if SiteSetting.matrix_homeserver.blank?

    true
  end

  def error_message
    if !SiteSetting.respond_to?(:chat_enabled) || !SiteSetting.chat_enabled
      I18n.t("site_settings.errors.requires_chat")
    elsif SiteSetting.matrix_homeserver.blank?
      I18n.t("site_settings.errors.blank_matrix_homeserver")
    end
  end
end
