module SystemHelper
  def login(user)
    visit new_user_session_path

    expect(page).to have_selector("input[name='user[email]']", wait: 5)

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_button "ログイン"

    expect(page).to have_current_path(home_index_path)
  end
end
