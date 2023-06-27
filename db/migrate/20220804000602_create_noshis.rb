class CreateNoshis < ActiveRecord::Migration[7.0]
  def change
    create_table :noshis do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.integer :ntype
      t.string :omotegaki
      t.string :names, array: true
      t.string :image
      t.string :paper_size
      t.integer :font_size
      t.integer :omotegaki_size
      t.decimal :omotegaki_margin_top
      t.decimal :names_margin_top

      t.timestamps
    end
    add_index :noshis, :ntype
    add_index :noshis, :omotegaki
    add_index :noshis, :names, using: 'gin'
  end
end
