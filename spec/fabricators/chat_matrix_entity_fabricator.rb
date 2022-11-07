# frozen_string_literal: true

Fabricator(:chat_matrix_entity) do
  matrix_event_id { sequence(:matrix_id) { |i| "$event-#{i}:matrix.discourse.org" } }
end
