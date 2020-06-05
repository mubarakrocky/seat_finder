Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'root#index'

  resource :seats, only: [] do
    post :find, on: :collection
  end
end
