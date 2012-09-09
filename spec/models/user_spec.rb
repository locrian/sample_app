# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  email           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean          default(FALSE)
#

require 'spec_helper'

describe User do
  before { @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar") }
 
  subject { @user }

  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:microposts) }
  it { should respond_to(:feed) }  

  it { should be_valid }
  it { should_not be_admin }
  
  describe "with admin attribute set to 'true'" do
    before do
      @user.save
      @user.toggle!(:admin)
    end
    
    it { should be_admin }
  end

  describe "remember token" do
    before { @user.save } 
    its(:remember_token) { should_not be_blank }
  end
 
  describe "when name is not present" do	# Tests if the username is missing
    before { @user.name = " " }
    it { should_not be_valid }
  end

  describe "when email is not present" do	# Test if the password is missing
    before { @user.email = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do		# Test the size of the username
    before { @user.name = "a" * 51 }      	#Before the test it sets de variable name to "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" 
    it { should_not be_valid }
  end

  describe "when email format is invalid" do	# Test for invalid e-mail formats
    it "should be invalid" do
      addresses = %w[user@lol,com user_at_lol.org exampe.lol@lol@teste_manhoso.com teste@teste+manhoso.com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        @user.should_not be_valid
      end
    end
  end

  describe "when email format is valid" do	# Test for valid e-mail formats
    it "should be valid" do
      addresses = %w[user@lol.COM A_US-ER@f.b.org first.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        @user.should be_valid
      end
    end
  end

  describe "when email adress is already taken" do	# Test for email duplication
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase 
      user_with_same_email.save
    end
    
    it { should_not be_valid }
  end

  describe "when password is not present" do		# Test for missing password
    before { @user.password = @user.password_confirmation = " " }
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do	# Test for password mismatch
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "when password confirmation is nil" do		# Test for null password confirmation, by default Rails accept nil and do not compare 
    before { @user.password_confirmation = nil }  		# the password and confirmation, so we need this test
    it { should_not be_valid }
  end

  describe "return value of authenticate method" do		# Test to compare the submited password with username
    before { @user.save }
    let(:found_user) { User.find_by_email(@user.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }

      it { should_not == user_for_invalid_password }
      specify { user_for_invalid_password.should be_false } 			#Same as "It", but "sounds better" in the current statement
    end
  end

  describe "with a password that's to short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }		#Specify the minimum size of the password to be 5
    it { should be_invalid }
  end

  describe "email address with mixed case" do					# Tests if the email is downcase before inserting into the database
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

    it "should be saved as all lower-case" do
      @user.email = mixed_case_email
      @user.save
      @user.reload.email.should == mixed_case_email.downcase
    end
  end

  describe "micropost associations" do

    before { @user.save }
    let!(:older_micropost) do 
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end

    it "should have the right microposts in the right order" do
      @user.microposts.should == [newer_micropost, older_micropost]
    end

    it "should destroy associated microposts" do
      microposts = @user.microposts
      @user.destroy
      microposts.each do |micropost|
        Micropost.find_by_id(micropost.id).should be_nil
      end
    end
   
    describe "status" do
      let(:unfollowed_post) do
        FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
      end

      its(:feed) { should include(newer_micropost) }
      its(:feed) { should include(older_micropost) }
      its(:feed) { should_not include(unfollowed_post) }
    end
  end
end



