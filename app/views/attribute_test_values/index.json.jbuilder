json.array!(@attribute_test_values) do |attribute_test_value|
  json.extract! attribute_test_value, :id
  json.url attribute_test_value_url(attribute_test_value, format: :json)
end
