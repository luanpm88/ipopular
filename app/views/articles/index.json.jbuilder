json.array!(@articles) do |article|
  json.extract! article, :id, :name, :content, :content_html, :content_plain, :infobox_template_id, :for_test
  json.url article_url(article, format: :json)
end
