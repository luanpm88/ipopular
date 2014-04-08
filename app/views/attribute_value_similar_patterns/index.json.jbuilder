json.array!(@attribute_value_similar_patterns) do |attribute_value_similar_pattern|
  json.extract! attribute_value_similar_pattern, :id, :attribute_value_id, :value, :paragraph, :sentence, :word
  json.url attribute_value_similar_pattern_url(attribute_value_similar_pattern, format: :json)
end
