class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_values
  has_many :attribute_value_similar_patterns
  
  @@template = 'university'
  
  def self.create_line_feature(string)
    features = []
    
    features << "value_of_token="+string
    
    if self.is_number(string.gsub(",",""))
      features << "type=Number"
    else
      features << "type=String"
    end
    
    if !/^\"[^\"]+\"$/.match(string).nil?
      features << "enclosed_1=1"
    end
    
    if !/^\"\'[^\"\']+\'\"$/.match(string).nil?
      features << "enclosed_2=1"
    end
    
    if self.is_number(string) && string.length == 2
      features << "two_digit_number=1"    
    end
    
    if self.is_number(string) && string.length == 4
      features << "four_digit_number=1"    
    end
    
    if self.is_number(string)
      features << "number=1"
    end    
    
    if self.is_number(string.gsub(",","")) && !self.is_number(string)
      features << "formated_number_1=1"
    end
    
    if !/^[0-9\,]+\s((mill\.)|(bill\.)|(thous\.))$/.match(string).nil?
      features << "formated_number_2=1"
    end
    
    if !/^[a-zA-Z]+$/.match(string).nil?
      features << "alphanum_char=1"
    end
    
    if !/^[a-zA-Z]+\.$/.match(string).nil?
      features << "alphanum_char_dot=1"
    end
    
    if !/((km)|(mi)|(miles))/.match(string).nil?
      features << "token_1=1"
    end
    
    if !/http/.match(string).nil?
      features << "token_2=1"
    end
    
    if !/\?/.match(string).nil?
      features << "token_3=1"
    end
    
    if !/\./.match(string).nil?
      features << "token_4=1"
    end
    
    return features
    
  end
  
  def self.write_log(log)
    str = ""
    if File.file?("public/log.txt")
      f = File.open("public/log.txt")
      while(line = f.gets)
        str += line
      end
    end
    str += log + " : " + Time.now.strftime("%d/%m/%Y %H:%M:%S") + "\n"
    
    File.open("public/log.txt", "w") { |file| file.write str }
  end
  
  ##FEATUREs Functions
  def f_small_token(string)
    if string.length < 10
      return 1
    else
      return 0
    end
  end
  
  def self.ed(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) {Array.new(n+1)}
  
    (0..m).each {|i| d[i][0] = i}
    (0..n).each {|j| d[0][j] = j}
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                    d[i-1][j-1]       # no operation required
                  else
                    [ d[i-1][j]+1,    # deletion
                      d[i][j-1]+1,    # insertion
                      d[i-1][j-1]+1,  # substitution
                    ].min
                  end
      end
    end
    d[m][n]
  end
  
  def self.is_number(str)
    true if Float(str) rescue false
  end
  
  def self.similarity_measure(str1, str2)
    str1 = str1.gsub(",","")
    str2 = str2.gsub(",","")
    
    if self.is_number(str1) ^ self.is_number(str2)
      return false
    elsif self.is_number(str1)
      num1 = str1.to_f
      num2 = str2.to_f
      
      if (num1-num2).abs <= (1.00/1000.00)*num1
        return true
      else
        return false
      end     
      
    elsif !self.is_number(str1)
      if self.ed(str1.to_s, str2.to_s) <= (1.00/4.00)*str1.length
        return true
      else
        return false
      end
    end 
    
  end
  
  ##1
  def self.import(maxxx)
    #infobox template
    infobox_template = InfoboxTemplate.where(name: @@template).first
    infobox_template.articles.delete_all
    
    # new method
    reader = Nokogiri::XML::Reader(File.open("/media/luan/01CF3161B4B56810/MyThesis/enwiki-20110115-pages-articles.xml"))
    @count = 0
    @logstr = '';
    reader.each do |node|
            if node.name == 'page' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
                    
                    if @count < maxxx
                            page = Nokogiri::XML(node.outer_xml)
                            # Article.create(:name => page.css("title").text, :content => page.css("content").text)
                            
                            content = page.css("text").text
                            
                            val = /\{\{infobox\s*#{infobox_template.name}(.+)((.*)(\{\{(.+)\}\})(.*))*\}\}/m.match(content.downcase)
                            if !val.nil?
                              
                              Article.create(:title => page.css("title").text,
                                             :content => page.css("text").text,
                                             :content_html => Wikitext::Parser.new.parse(page.css("text").text.gsub(/\[\[\s*category\:[^\[\]]+\]\]/mi, '')),
                                             :infobox_template_id => infobox_template.id
                                            )
                              @count = @count + 1
                              puts @count
                              
                              article = Article.where(:title => page.css("title").text).first
                              
                              pparts = val[1].split("}}")
                              str = ""
                              pparts.each do |p|
                                if !/\{\{/m.match(p).nil?
                                  str += p+"}}"
                                else
                                  str += p
                                  break
                                end
                              end
                              
                              
                              inner = str
                              lines = inner.split(/\n\s*\|/m)
                              lines.each do |line|
                                if /\=/.match(line)
                                  parts = line.split("=")
                                  attr_name = parts[0].gsub(/\s*\|\s*/,"").strip
                                  attr_value = line.gsub(parts[0]+'=','').strip
                                                                    
                                  attribute = infobox_template.attributes.where(name: attr_name).first
                                  if attribute.nil?                                    
                                    attribute = infobox_template.attributes.create(name: attr_name)
                                  end
                                  
                                  puts attribute.name
                                  @logstr += attribute.name + "\n"                                  
                                  
                                  attribute_value = AttributeValue.where(article_id: article.id, attribute_id: attribute.id).first
                                  if attribute_value.nil?
                                    raw_value = attr_value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'').gsub(/<!--[\s\S]*?-->/,'').strip
                                    if raw_value != ""
                                      AttributeValue.create(article_id: article.id, attribute_id: attribute.id, value: attr_value, raw_value: raw_value)
                                    end
                                  end
                                  
                                end
                                # sleep(0.1)
                              end
                              
                              puts "#######################"
                              @logstr += "#################\n"
                                                            
                            end
                            
                            #sleep(0.1)
                    else
                      break
                    end
            end
    end
    
    count_articles = (Article.count/2).to_i
    
    Article.update_all("for_test=0","id <= "+count_articles.to_s)
    Article.update_all("for_test=1","id > "+count_articles.to_s)
    
    File.open("public/log.txt", "w") { |file| file.write @logstr }
  end
  
  ##2
  def self.find_first_paragraphs    
    infobox_template = InfoboxTemplate.where(name: @@template).first    
    num = 5
    
    infobox_template.articles.all.each do |article|
      content_fixed = article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/m,'<\1>').gsub(/\<p\>(\<a\>(.{2,5})\:[^<]+\<\/a\>\s?)+\<\/p\>/mi, '')      
      while content_fixed.gsub!(/\{\{[^\{\}]*?\}\}/m, ''); end      
      while content_fixed.gsub!(/\{[^\{\}]*?\}/m, ''); end
      while content_fixed.gsub!(/\[\[[^\[\]]*?\]\]/m, ''); end      
      content_fixed = content_fixed.gsub(/\&lt\;ref(.*?)\&gt\;(.*?)\&lt\;\/ref\&gt\;/im,"").gsub(/[\{\}]/,'')      
      
      pa = Nokogiri::HTML(content_fixed)
      
      count = 1
      str = ''
      pa.css("p").each do |paragraph|
        paragraph = Sanitize.clean(paragraph.text).strip.gsub(/\n+/,' ')
        
        if paragraph != ""
          puts paragraph + "\n"
          str += paragraph + "\n"
          
          if paragraph.split(" ").count > 20
            count += 1
          end         
        end
        
        if count > num        
          break
        end        
        
        #sleep(0.5)
      end
      
      #save first paragraphs to article
      article.content_plain = str.strip
      article.save
      
      puts "===============================================================\n"
    end
  end
  
  ##3
  def self.set_attribute_status
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.each do |attribute|
      count = AttributeValue.where(attribute_id: attribute.id).count("article_id",distinct: true)
      total = infobox_template.articles.where(for_test: 0).count
      
      if (count.to_f / total.to_f) < 0.05
        attribute.status = 0
      else
        attribute.status = 1
      end
      
      attribute.save
      
    end
  end
  
  ##4
  def self.create_raw_attribute_value
    
    AttributeValueSimilarPattern.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.articles.each do |article|      
      article.attribute_values.each do |attribute_value|        
        
        puts attribute_value.raw_value
        att_parts = attribute_value.raw_value.split(" ")
        
        a_parts = article.content_plain.split("\n")
        if !a_parts.nil?
          a_parts.each_with_index do |paragraph,p_index|
            p_parts = paragraph.split(/(.{4,}?[\.\?\!]) ?/).reject! { |c| c.empty? }
            
            if !p_parts.nil?
              p_parts.each_with_index do |sentence,s_index|
                
                s_parts = sentence.split(" ")
                s_parts.each_with_index do |word,w_index|
                
                  str = ""
                  (0..(att_parts.count-1)).each do |i|
                    str += s_parts[w_index+i] + " " if !s_parts[w_index+i].nil?
                  end
                  if self.similarity_measure(str.strip, attribute_value.raw_value)
                    puts attribute_value.raw_value + ": ok"
                    
                    related_sentences = [sentence]
                    #get window tokens
                    pre_tokens = ""
                    pre_tokens_1 = ""
                    (1..5).each do |j|
                      if w_index - j >= 0
                        pre_tokens = s_parts[w_index - j] + " " + pre_tokens
                      else
                        #if s_index - 1 >= 0
                        #  p_s_parts = p_parts[s_index - 1].split(" ")
                        #  pre_tokens_1 += p_s_parts[p_s_parts.count - (5-j) - 1] + " " if p_s_parts.count - (5-j) - 1 >= 0
                        #else
                        #  if p_index - 1 >= 0
                        #    a_s_parts = a_parts[p_index - 1].split(" ")
                        #    pre_tokens_1 += a_s_parts[a_s_parts.count - (5-j) - 1] + " " if a_s_parts.count - (5-j) - 1 >= 0
                        #  end                          
                        #end                        
                      end
                    end
                    pre_tokens = pre_tokens_1 + pre_tokens.strip
                    #puts pre_tokens + "---" + str.strip
                    #sleep(1)
                    
                    #get window tokens
                    post_tokens = ""
                    post_tokens_1 = ""
                    (1..5).each do |j|
                      if w_index + (att_parts.count-1) + j <= s_parts.count-1
                        post_tokens += s_parts[w_index + (att_parts.count-1) + j] + " "
                      else
                        #if s_index + 1 <= p_parts.count-1
                        #    p_s_parts = p_parts[s_index + 1].split(" ")
                        #    post_tokens_1 = p_s_parts[5-j] + " " + post_tokens_1 if 5-j >= 0
                        #else
                        #  if p_index + 1 <= a_parts.count-1
                        #    a_s_parts = a_parts[p_index + 1].split(" ")
                        #    post_tokens_1 = a_s_parts[5-j] + " " + post_tokens_1 if 5-j >= 0
                        #  end                          
                        #end                        
                      end
                    end
                    post_tokens = post_tokens + post_tokens_1.strip
                    windows_str = pre_tokens + "---" + str.strip + "---" + post_tokens
                    puts windows_str
                    
                    
                    long_p = 0
                    if p_parts.count > 2
                      long_p = 1
                    end
                    
                    avsp = attribute_value.attribute_value_similar_patterns.create(infobox_template_id: infobox_template.id,
                                                                                   article_id: attribute_value.article_id,
                                                                                   attribute_id: attribute_value.attribute_id,
                                                                                   value: str.strip,
                                                                                   paragraph: p_index,
                                                                                   sentence: s_index,
                                                                                   word: w_index,
                                                                                   long_paragraph: long_p,
                                                                                   window_pre: pre_tokens,
                                                                                   window_post: post_tokens)
                    
                  end
                end
              end
            end
          end
        end
        
      end
    end
    
  end
  
  ##5
  def self.create_crf_training_data   
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf`
    `mkdir public/crf/#{infobox_template.name}`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      
      train_lines = ""
      attribute.attribute_value_similar_patterns.joins(:article).where("articles.for_test = ?", 0).each do |pattern|

        
        puts pattern.window_pre + " " + pattern.value + " " + pattern.window_post
        
        full_string = pattern.window_pre + " " + pattern.value + " " + pattern.window_post
        full_string = full_string.gsub(/\s+/,' ')
        
        tags = `java -jar bin/POS.jar "#{full_string.strip.gsub(/[\,\.\!\?\"\']/,'')}"`
        
        puts tags.split(" ").count.to_s + full_string.split(" ").count.to_s
        
        tags = tags.split(" ")
        
        train_line = ""
        pattern.window_pre.gsub(/\s+/,' ').split(" ").each_with_index do |word,index|
          tag = tags[index]
          train_line += "PRE" + "\t" + self.create_line_feature(word.strip).join("\t") + "\t" + "POS=" + tag.to_s
          train_line += "\n"
        end
        
        pattern.value.gsub(/\s+/,' ').split(" ").each_with_index do |word,index|
          tag = tags[index + pattern.window_pre.gsub(/\s+/,' ').split(" ").count]
          train_line += "VAL" + "\t" + self.create_line_feature(word.strip).join("\t") + "\t" + "POS=" + tag.to_s
          train_line += "\t" + "small_token=1" if word.length < 10
          train_line += "\t" + "long_paragraph=1" if pattern.long_paragraph == 1
          train_line += "\t" + "paragraph=" + pattern.paragraph.to_s
          train_line += "\t" + "sentence=" + pattern.sentence.to_s
          train_line += "\t" + "word=" + pattern.word.to_s                    
          train_line += "\n"
        end
        
        pattern.window_post.gsub(/\s+/,' ').split(" ").each_with_index do |word,index|
          tag = tags[index + pattern.window_pre.gsub(/\s+/,' ').split(" ").count + pattern.value.gsub(/\s+/,' ').split(" ").count]
          train_line += "POT" + "\t" + self.create_line_feature(word.strip).join("\t") + "\t" + "POS=" + tag.to_s
          train_line += "\n"
        end
        
        train_line += "\n"
        
        train_lines += train_line
        
      end
      
      if train_lines != ''
        `mkdir public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
        File.open("public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt", "w") { |file| file.write  train_lines }
      end
      
    end
    
  end
  
  
  
  ############
  def self.run_all
    ##1
    self.import(40)
    self.write_log("######### 1 import")
    
    ##2
    self.find_first_paragraphs
    self.write_log("######### 2 find_first_paragraphs")
    
    ##3
    self.set_attribute_status
    self.write_log("######### 3 set_attribute_status")
    
    ##4
    self.create_raw_attribute_value
    self.write_log("######### 4 create_raw_attribute_value")
    
    ##5
    self.create_crf_training_data
    self.write_log("######### 5 create_crf_training_data")
    
  end
  
end
