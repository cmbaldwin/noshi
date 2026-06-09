class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email, null: false
      t.string :name
      t.string :avatar_url
      t.boolean :admin, null: false, default: false
      t.string :stripe_customer_id

      t.timestamps
    end

    add_index :users, %i[provider uid], unique: true
    add_index :users, :email
    add_index :users, :stripe_customer_id
  end
end
