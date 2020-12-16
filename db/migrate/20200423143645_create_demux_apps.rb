class CreateDemuxApps < ActiveRecord::Migration[5.1]
  def change
    create_table :demux_apps do |t|
      t.string :name
      t.text :description
      t.string :secret
      t.string :entry_url
      t.string :signal_url
      t.text :signals, array:true, default: []
      t.text :account_types, array:true, default: []
      t.jsonb :configuration, default: {}

      t.timestamps
    end
    add_index :demux_apps, :signals, using: "gin"
    add_index :demux_apps, :configuration, using: "gin"
    add_index :demux_apps, :secret, unique: true
  end
end
