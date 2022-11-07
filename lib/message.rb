# frozen_string_literal: true

module DiscourseChatMatrix::Message
  def self.process_cooked(html)
    fragment = Nokogiri::HTML5.fragment(html)

    # Replace emojis with their Unicode versions
    fragment
      .css("img.emoji")
      .each do |node|
        if replacement = emoji_map[node["title"][1...-1]]
          node.replace(replacement)
        end
      end

    fragment.to_html
  end

  private

  def self.emoji_map
    Emoji.unicode_replacements.invert
  end
end
