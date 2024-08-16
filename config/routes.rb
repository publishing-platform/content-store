Rails.application.routes.draw do
  scope format: false do
    # The /api/content route is used for requests via the public API
    get "/api/content(/*path_without_root)" => "content_items#show", :as => :content_item_api, :public_api_request => true

    get "/content(/*path_without_root)" => "content_items#show", :as => :content_item    
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
