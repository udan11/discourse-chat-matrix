# frozen_string_literal: true

class CreateChatMatrixEntities < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_matrix_entities do |t|
      t.string :entity_type
      t.bigint :entity_id
      t.string :matrix_event_id
      t.timestamps
    end

    add_index :chat_matrix_entities, %i[entity_type entity_id], unique: true
    add_index :chat_matrix_entities, :matrix_event_id, unique: true
  end
end
