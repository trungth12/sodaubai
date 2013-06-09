require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe MonHocsController do

  # This should return the minimal set of attributes required to create a valid
  # MonHoc. As you add validations to MonHoc, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { "ma_mon_hoc" => "MyString" } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # MonHocsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all mon_hocs as @mon_hocs" do
      mon_hoc = MonHoc.create! valid_attributes
      get :index, {}, valid_session
      assigns(:mon_hocs).should eq([mon_hoc])
    end
  end

  describe "GET show" do
    it "assigns the requested mon_hoc as @mon_hoc" do
      mon_hoc = MonHoc.create! valid_attributes
      get :show, {:id => mon_hoc.to_param}, valid_session
      assigns(:mon_hoc).should eq(mon_hoc)
    end
  end

  describe "GET new" do
    it "assigns a new mon_hoc as @mon_hoc" do
      get :new, {}, valid_session
      assigns(:mon_hoc).should be_a_new(MonHoc)
    end
  end

  describe "GET edit" do
    it "assigns the requested mon_hoc as @mon_hoc" do
      mon_hoc = MonHoc.create! valid_attributes
      get :edit, {:id => mon_hoc.to_param}, valid_session
      assigns(:mon_hoc).should eq(mon_hoc)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new MonHoc" do
        expect {
          post :create, {:mon_hoc => valid_attributes}, valid_session
        }.to change(MonHoc, :count).by(1)
      end

      it "assigns a newly created mon_hoc as @mon_hoc" do
        post :create, {:mon_hoc => valid_attributes}, valid_session
        assigns(:mon_hoc).should be_a(MonHoc)
        assigns(:mon_hoc).should be_persisted
      end

      it "redirects to the created mon_hoc" do
        post :create, {:mon_hoc => valid_attributes}, valid_session
        response.should redirect_to(MonHoc.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved mon_hoc as @mon_hoc" do
        # Trigger the behavior that occurs when invalid params are submitted
        MonHoc.any_instance.stub(:save).and_return(false)
        post :create, {:mon_hoc => { "ma_mon_hoc" => "invalid value" }}, valid_session
        assigns(:mon_hoc).should be_a_new(MonHoc)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        MonHoc.any_instance.stub(:save).and_return(false)
        post :create, {:mon_hoc => { "ma_mon_hoc" => "invalid value" }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested mon_hoc" do
        mon_hoc = MonHoc.create! valid_attributes
        # Assuming there are no other mon_hocs in the database, this
        # specifies that the MonHoc created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        MonHoc.any_instance.should_receive(:update_attributes).with({ "ma_mon_hoc" => "MyString" })
        put :update, {:id => mon_hoc.to_param, :mon_hoc => { "ma_mon_hoc" => "MyString" }}, valid_session
      end

      it "assigns the requested mon_hoc as @mon_hoc" do
        mon_hoc = MonHoc.create! valid_attributes
        put :update, {:id => mon_hoc.to_param, :mon_hoc => valid_attributes}, valid_session
        assigns(:mon_hoc).should eq(mon_hoc)
      end

      it "redirects to the mon_hoc" do
        mon_hoc = MonHoc.create! valid_attributes
        put :update, {:id => mon_hoc.to_param, :mon_hoc => valid_attributes}, valid_session
        response.should redirect_to(mon_hoc)
      end
    end

    describe "with invalid params" do
      it "assigns the mon_hoc as @mon_hoc" do
        mon_hoc = MonHoc.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        MonHoc.any_instance.stub(:save).and_return(false)
        put :update, {:id => mon_hoc.to_param, :mon_hoc => { "ma_mon_hoc" => "invalid value" }}, valid_session
        assigns(:mon_hoc).should eq(mon_hoc)
      end

      it "re-renders the 'edit' template" do
        mon_hoc = MonHoc.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        MonHoc.any_instance.stub(:save).and_return(false)
        put :update, {:id => mon_hoc.to_param, :mon_hoc => { "ma_mon_hoc" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested mon_hoc" do
      mon_hoc = MonHoc.create! valid_attributes
      expect {
        delete :destroy, {:id => mon_hoc.to_param}, valid_session
      }.to change(MonHoc, :count).by(-1)
    end

    it "redirects to the mon_hocs list" do
      mon_hoc = MonHoc.create! valid_attributes
      delete :destroy, {:id => mon_hoc.to_param}, valid_session
      response.should redirect_to(mon_hocs_url)
    end
  end

end