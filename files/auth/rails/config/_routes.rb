get 'login', to: 'sessions#new'
get 'signup', to: 'registrations#new'
get 'logout', to: 'sessions#destroy'
delete 'logout', to: 'sessions#destroy'
