class AddUnaccentExtension < ActiveRecord::Migration[6.1]
  def up
    enable_extension "unaccent"
  end

  def down
    disable_extension "unaccent"
  end
end
