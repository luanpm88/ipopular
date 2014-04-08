require 'test_helper'

class AttributeValueSimilarPatternsControllerTest < ActionController::TestCase
  setup do
    @attribute_value_similar_pattern = attribute_value_similar_patterns(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:attribute_value_similar_patterns)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create attribute_value_similar_pattern" do
    assert_difference('AttributeValueSimilarPattern.count') do
      post :create, attribute_value_similar_pattern: { attribute_value_id: @attribute_value_similar_pattern.attribute_value_id, paragraph: @attribute_value_similar_pattern.paragraph, sentence: @attribute_value_similar_pattern.sentence, value: @attribute_value_similar_pattern.value, word: @attribute_value_similar_pattern.word }
    end

    assert_redirected_to attribute_value_similar_pattern_path(assigns(:attribute_value_similar_pattern))
  end

  test "should show attribute_value_similar_pattern" do
    get :show, id: @attribute_value_similar_pattern
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @attribute_value_similar_pattern
    assert_response :success
  end

  test "should update attribute_value_similar_pattern" do
    patch :update, id: @attribute_value_similar_pattern, attribute_value_similar_pattern: { attribute_value_id: @attribute_value_similar_pattern.attribute_value_id, paragraph: @attribute_value_similar_pattern.paragraph, sentence: @attribute_value_similar_pattern.sentence, value: @attribute_value_similar_pattern.value, word: @attribute_value_similar_pattern.word }
    assert_redirected_to attribute_value_similar_pattern_path(assigns(:attribute_value_similar_pattern))
  end

  test "should destroy attribute_value_similar_pattern" do
    assert_difference('AttributeValueSimilarPattern.count', -1) do
      delete :destroy, id: @attribute_value_similar_pattern
    end

    assert_redirected_to attribute_value_similar_patterns_path
  end
end
