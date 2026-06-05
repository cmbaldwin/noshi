class AddOrientationToBackgrounds < ActiveRecord::Migration[8.0]
  def change
    add_column :backgrounds, :orientation, :string, null: false, default: "landscape"
  end
end
