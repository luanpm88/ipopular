require 'test_helper'

class AttributeTestValuesControllerTest < ActionController::TestCase
  setup do
    @attribute_test_value = attribute_test_values(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:attribute_test_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create attribute_test_value" do
    assert_difference('AttributeTestValue.count') do
      post :create, attribute_test_value: {  }
    end

    assert_redirected_to attribute_test_value_path(assigns(:attribute_test_value))
  end

  test "should show attribute_test_value" do
    get :show, id: @attribute_test_value
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @attribute_test_value
    assert_response :success
  end

  test "should update attribute_test_value" do
    patch :update, id: @attribute_test_value, attribute_test_value: {  }
    assert_redirected_to attribute_test_value_path(assigns(:attribute_test_value))
  end

  test "should destroy attribute_test_value" do
    assert_difference('AttributeTestValue.count', -1) do
      delete :destroy, id: @attribute_test_value
    end

    assert_redirected_to attribute_test_values_path
  end
end
