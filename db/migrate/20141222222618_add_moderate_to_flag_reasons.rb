class AddModerateToFlagReasons < ActiveRecord::Migration
  def change
    add_column :flag_reasons, :moderate, :boolean, null: false, default: true
  end
end
