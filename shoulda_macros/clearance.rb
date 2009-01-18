module Clearance 
  module Shoulda

    # STATE OF AUTHENTICATION

    def should_be_logged_in_as(&block)
      should "be logged in as #{block.bind(self).call}" do
        user = block.bind(self).call
        assert_not_nil user, 
          "please pass a User. try: should_be_logged_in_as { @user }"
        assert_equal user.id,   session[:user_id], 
          "session[:user_id] is not set to User's id"
        assert_equal user.salt, session[:salt], 
          "session[:salt] is not set to User's salt"
      end
    end

    def should_be_logged_in_and_email_confirmed_as(&block)
      should_be_logged_in_as &block
      
      should "have confirmed email" do
        user = block.bind(self).call
        
        assert_not_nil user
        assert_equal user, assigns(:user)
        assert assigns(:user).email_confirmed?
      end
    end
    
    def should_not_be_logged_in
      should "not be logged in" do
        assert_nil session[:user_id]
        assert_nil session[:salt]
      end
    end

    def should_deny_access_on(command, opts = {})
      context "on #{command}" do
        setup { eval command }
        should_deny_access(opts)
      end
    end

    def should_deny_access(opts = {})
      if opts[:flash]
        should_set_the_flash_to opts[:flash]
      else
        should_not_set_the_flash
      end
      
      should "respond with 401 Unauthorized and render login template" do
        assert_response :unauthorized, 
          "access was expected to be denied (401 unauthorized)"
        assert_template "sessions/new",
          "template was expected to be login (sessions/new)"
      end
    end
    
    # CONTEXTS

    def logged_in_user_context(&blk)
      context "A logged in user" do
        setup do
          @user = Factory(:registered_user)
          @user.confirm_email!
          login_as @user
        end
        merge_block(&blk)
      end
    end

    def public_context(&blk)
      context "The public" do
        setup { logout }
        merge_block(&blk)
      end
    end
    
    # RENDERING
    
    def should_render_nothing
      should "render nothing" do
        assert @response.body.blank?
      end
    end
    
    # REDIRECTS
    
    def should_redirect_to_url_after_create
      should_redirect_to "@controller.send(:url_after_create)"
    end
    
    def should_redirect_to_url_after_update
      should_redirect_to "@controller.send(:url_after_update)"
    end
    
    def should_redirect_to_url_after_destroy
      should_redirect_to "@controller.send(:url_after_destroy)"
    end
    
    # VALIDATIONS
    
    # This Shoulda macro also depends on Factory Girl
    # :on => :save, :create, or :update    
    def should_validate_confirmation_of(attribute, opts = {})
      raise ArgumentError if opts[:factory].nil?
      raise ArgumentError if opts[:on].nil?
      
      if opts[:on] == :create
        should_validate_attribute_is_not_blank    opts[:factory], attribute
        should_validate_confirmation_is_not_blank opts[:factory], attribute
        should_validate_confirmation_is_not_bad   opts[:factory], attribute
      end
    end
    
    def should_validate_attribute_is_not_blank(factory, attribute)
      should "validate #{attribute} is not blank" do
        model = Factory.build(factory, blank_attribute_options(attribute))
        model.save
        assert_confirmation_error(model, attribute, 
          "#{attribute} cannot be blank")
      end
    end
    
    def should_validate_confirmation_is_not_blank(factory, attribute)
      should "validate #{attribute}_confirmation is not blank" do
        model = Factory.build(factory, blank_confirmation_options(attribute))
        model.save
        assert_confirmation_error(model, attribute, 
          "#{attribute}_confirmation cannot be blank")
      end
    end
    
    def should_validate_confirmation_is_not_bad(factory, attribute)
      should "validate #{attribute}_confirmation is different than #{attribute}" do
        model = Factory.build(factory, bad_confirmation_options(attribute))
        model.save
        assert_confirmation_error(model, attribute, 
          "#{attribute}_confirmation cannot be different than #{attribute}")
      end
    end
    
  end
end

module Clearance
  module Shoulda
    module Helpers
      def blank_attribute_options(attribute)
        opts = { attribute => "" }
        opts.merge("#{attribute}_confirmation".to_sym => attribute.to_s)
      end

      def bad_confirmation_options(attribute)
        opts = { attribute => attribute.to_s }
        opts.merge("#{attribute}_confirmation".to_sym => "not_#{attribute}")
      end

      def blank_confirmation_options(attribute)
        opts = { attribute => attribute.to_s }
        opts.merge("#{attribute}_confirmation".to_sym => "")
      end
      
      def assert_confirmation_error(model, attribute, message = "confirmation error")
        assert model.errors.on(attribute).include?("doesn't match confirmation"), 
          message
      end
    end
  end
end

class Test::Unit::TestCase
  include Clearance::Shoulda::Helpers
end
Test::Unit::TestCase.extend(Clearance::Shoulda)