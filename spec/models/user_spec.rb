require 'rails_helper'

RSpec.describe User, type: :model do
  before do
    @user = User.new(
      email: 'test@example.com',
      password: 'password',
      password_confirmation: 'password',
      name: 'テストユーザー'
    )
  end

  describe 'ユーザー作成のバリデーション' do
    context '有効な場合' do
      it '全ての属性が有効であればユーザーを作成できる' do
        expect(@user).to be_valid
      end
    end

    context '無効な場合' do
      it 'メールアドレスが空であれば無効である' do
        @user.email = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to include('メールアドレスを入力してください')
      end

      it '無効な形式のメールアドレスは無効である' do
        @user.email = 'invalid_email'
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to include('は不正な値です')
      end

      it '重複したメールアドレスは無効である' do
        User.create!(
          email: 'test@example.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'テストユーザー'
        )
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to include('はすでに存在します')
      end

      it 'パスワードが空であれば無効である' do
        @user.password = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:password]).to include('パスワードを入力してください')
      end

      it 'パスワードが6文字未満であれば無効である' do
        @user.password = 'short'
        @user.password_confirmation = 'short'
        expect(@user).not_to be_valid
        expect(@user.errors[:password]).to include('は6文字以上で入力してください')
      end

      it 'パスワード確認が一致しなければ無効である' do
        @user.password_confirmation = 'different'
        expect(@user).not_to be_valid
        expect(@user.errors[:password_confirmation]).to include('とパスワードの入力が一致しません')
      end

      it 'ユーザー名が空であれば無効である' do
        @user.name = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:name]).to include('ユーザー名を入力してください')
      end
    end
  end

  describe 'アバター画像の添付' do
    it '有効な画像ファイルが添付されている場合に有効' do
      user = User.new(
        email: 'test@example.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'テストユーザー'
      )
      user.avatar.attach(
        io: StringIO.new("dummy image data"),
        filename: 'dummy_image.png',
        content_type: 'image/png'
      )
      expect(user.avatar).to be_attached
      expect(user).to be_valid
    end

    it '無効な形式のファイルを添付した場合は無効' do
      user = User.new(
        email: 'test@example.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'テストユーザー'
      )
      user.avatar.attach(
        io: StringIO.new("invalid data"),
        filename: 'invalid.txt',
        content_type: 'text/plain'
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include('ファイル形式はJPEG, PNG, GIFのみアップロード可能です。')
    end
  end
  describe '自己紹介文と名前の長さチェック' do
    context '無効な場合' do
      it 'ユーザー名が50文字を超えると無効である' do
        @user.name = 'a' * 51
        expect(@user).not_to be_valid
        expect(@user.errors[:name]).to include('50文字以内で入力してください')
      end

      it '自己紹介文が500文字を超えると無効である' do
        @user.introduction = 'a' * 501
        expect(@user).not_to be_valid
        expect(@user.errors[:introduction]).to include('500文字以内で入力してください')
      end
    end

    context '有効な場合' do
      it 'ユーザー名が50文字以内であれば有効である' do
        @user.name = 'a' * 50
        expect(@user).to be_valid
      end

      it '自己紹介文が500文字以内であれば有効である' do
        @user.introduction = 'a' * 500
        expect(@user).to be_valid
      end
    end
  end
end
