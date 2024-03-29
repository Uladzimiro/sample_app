require 'spec_helper'

include ApplicationHelper

describe "Static Pages" do

  subject { page }
  
  shared_examples_for "all static pages" do
    it { should have_selector('h1', text: heading) }
    it { should have_selector('title', text: full_title(page_title)) }
  end
  
  describe "Home page" do
    before { visit root_path }
    let(:heading)    { 'Sample App' }
    let(:page_title) { '' }
    
    it_should_behave_like "all static pages"
    it { should_not have_selector 'title', text: '| Home' }
    
    describe "for signed-in users" do
      let!(:user) { FactoryGirl.create(:user) }
      let!(:wrong_user) { FactoryGirl.create(:user, email: "wrong@gmail.com") }
      before do
        FactoryGirl.create(:micropost, user: user, content: "Lorem ipsum")
        FactoryGirl.create(:micropost, user: user, content: "Dolor sit amet")
        
        FactoryGirl.create(:micropost, user: wrong_user, content: "Tweet1")
        FactoryGirl.create(:micropost, user: wrong_user, content: "Tweet2")
        
        sign_in user
        visit root_path
      end
      
      it "should render the user's feed" do
        user.feed.each do |item|
          page.should have_selector("li##{item.id}", text: item.content)
        end
      end
      
      it "should have right number of microposts" do
        page.should have_selector("span", text: "#{user.feed.count} microposts")
      end
      
      
      describe "should contin delete links" do
        it "for own tweets" do
          user.microposts.each do |m|
            should have_link('delete', href: micropost_path(m))
          end
        end
        
        it "not for someone's tweets" do
          Micropost.where("user_id <> #{user.id}").each do |m|
            should_not have_link('delete', href: micropost_path(m))
          end
        end
      end
      
      describe "pagination" do
        before(:all) { 30.times  { |i| FactoryGirl.create(:micropost, user: user, content: "tweet #{i}") } }
        after(:all) { user.microposts.delete_all }
        
        it { should have_link('Next') }
        its(:html) { should match('>2</a>') }
        
        it "should list first tweets" do
          user.microposts.all[0..5].each do |tweet|
            page.should have_selector('li', text: tweet.content)
          end
        end
      end
      
      describe "follower/following counts" do
        let(:other_user) { FactoryGirl.create(:user, email: 'other@user.com') }
        before do
          other_user.follow!(user)
          visit root_path
        end
        
        it { should have_link("0 following", href: following_user_path(user)) }
        it { should have_link("1 followers", href: followers_user_path(user)) }
      end
    end    
  end

  describe "Help page" do
    before { visit help_path }
    let(:heading)    { 'Help' }
    let(:page_title) { 'Help' }
    
    it_should_behave_like "all static pages"
  end

  describe "About page" do
    before { visit about_path }
    let(:heading)    { 'About Us' }
    let(:page_title) { 'About Us' }
    
    it_should_behave_like "all static pages"
  end

  describe "Contact page" do
    before { visit contact_path }
    let(:heading)    { 'Contact' }
    let(:page_title) { 'Contact' }
    
    it_should_behave_like "all static pages"
  end
  
  it "should have the right links on the layout" do
    visit root_path
    click_link "About"
    should have_selector 'title', text: full_title('About Us')
    click_link "Help"
    should have_selector 'title', text: full_title('Help')
    click_link "Contact"
    should have_selector 'title', text: full_title('Contact')
    click_link "Home"
    should have_selector 'title', text: full_title('')
    should_not have_selector 'title', text: '| Home'
    click_link "Sign up now!"
    should have_selector 'title', text: full_title('Sign up')
  end
end
