# frozen_string_literal: true

class CreateChatMatrixUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_matrix_users do |t|
      t.bigint :user_id
      t.string :matrix_user_id
      t.timestamps
    end

    add_index :chat_matrix_users, :user_id, unique: true
    add_index :chat_matrix_users, :matrix_user_id, unique: true
  end
end
