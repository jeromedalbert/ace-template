devise_for :users
devise_scope :user do
  get 'login', to: 'devise/sessions#new'
  get 'signup', to: 'devise/registrations#new'
  get 'logout', to: 'devise/sessions#destroy'
  delete 'logout', to: 'devise/sessions#destroy'
end
