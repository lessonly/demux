class CreateDemuxApps < ActiveRecord::Migration[5.1]
  def change
    create_table :demux_apps do |t|
      t.string :name
      t.text :description
      t.string :secret
      t.string :entry_url

      t.timestamps
    end
    add_index :demux_apps, :secret, unique: true
  end
end
