# frozen_string_literal: true

Fabricator(:chat_matrix_channel) do
  chat_channel { Fabricate(:chat_channel) }
  matrix_room_id { sequence(:matrix_id) { |i| "!room-#{i}:matrix.discourse.org" } }
  matrix_room_alias { sequence(:matrix_id) { |i| "#chat-#{i}:matrix.discourse.org" } }
end
