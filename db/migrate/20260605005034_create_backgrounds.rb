class CreateBackgrounds < ActiveRecord::Migration[8.0]
  def change
    create_table :backgrounds do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      # pending -> approved -> rejected (moderation gate before public listing)
      t.string :status, null: false, default: "pending"
      t.integer :ratings_count, null: false, default: 0
      t.integer :ratings_sum, null: false, default: 0

      t.timestamps
    end

    add_index :backgrounds, :status
  end
end
