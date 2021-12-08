class AddIndicatorToDemuxApps < ActiveRecord::Migration[5.2]
  def change
    add_column :demux_apps, :indicator, :text
  end
end
