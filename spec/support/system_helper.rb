module SystemHelper
  def login(user)
    if user.provider.present?
      # SNSログインユーザーの場合はWarden経由で直接ログイン（Deviseヘルパー）
      login_as(user, scope: :user)
    else
      visit new_user_session_path

      expect(page).to have_selector("input[name='user[email]']", wait: 5)

      fill_in "user[email]", with: user.email
      fill_in "user[password]", with: "password"
      click_button "ログイン"

      expect(page).to have_current_path(root_path, wait: 5)
    end
  end
end
