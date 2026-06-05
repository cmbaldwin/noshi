class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :background, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    # One rating per user per background (re-rating updates the existing row).
    add_index :ratings, %i[user_id background_id], unique: true
  end
end
