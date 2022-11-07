# frozen_string_literal: true

Fabricator(:chat_matrix_user) do
  user { Fabricate(:user) }
  matrix_user_id { sequence(:matrix_id) { |i| "@user-#{i}:matrix.discourse.org" } }
end
