# frozen_string_literal: true

class CreateChatMatrixChannels < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_matrix_channels do |t|
      t.bigint :chat_channel_id
      t.string :matrix_room_id
      t.string :matrix_room_alias
      t.timestamps
    end

    add_index :chat_matrix_channels, :chat_channel_id, unique: true
    add_index :chat_matrix_channels, :matrix_room_id, unique: true
    add_index :chat_matrix_channels, :matrix_room_alias, unique: true
  end
end
