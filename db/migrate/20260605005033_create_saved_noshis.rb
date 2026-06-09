class CreateSavedNoshis < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_noshis do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      # The full set of generator inputs (ntype, omotegaki, names, paper size,
      # font/position settings). Re-applied client-side to regenerate the image.
      t.json :settings, null: false, default: {}

      t.timestamps
    end
  end
end
