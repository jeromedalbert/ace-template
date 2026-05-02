let(:user) { create(:user) }
let(:banana) { create(:banana, user: user) }

before { authenticate(user) }
