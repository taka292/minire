module SystemHelper
  def login(user)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_button "ログイン"
  end
end
