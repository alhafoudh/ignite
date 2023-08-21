class App
  include ActiveModel::Model

  attr_accessor :id, :name

  def self.all
    [
      App.new(id: '1', name: "App 1"),
    ]
  end

  def self.find(id)
    all.find do |app|
      app.id == id.to_s
    end
  end

  def container_name
    "app-#{id}"
  end
end