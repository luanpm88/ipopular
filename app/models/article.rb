class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_values
  has_many :attribute_value_similar_patterns
  has_many :attribute_test_values
  
  @@template = 'actor'
  @@no_attributes = []
  
  def self.create_hash_feature(hash,string)

    hash[:a] = string
    
    if self.is_number(string.gsub(",",""))
      hash[:b] = "Number"
    else
      hash[:b] = "String"
    end
    
    if !/^\"[^\"]+\"$/.match(string).nil? || !/^\'[^\']+\'$/.match(string).nil?
      hash[:c] = "1"
    end
    
    if !/^\"\'[^\"\']+\'\"$/.match(string).nil?
      hash[:d] = "1"
    end
    
    if self.is_number(string) && string.length == 2
      hash[:e] = "1"
    end
    
    if self.is_number(string) && string.length == 4
      hash[:f] = "1"
    end
    
    if self.is_number(string)
      hash[:g] = "1"
    end    
    
    if self.is_number(string.gsub(",","")) && !self.is_number(string)
      hash[:h] = "1"
    end
    
    if !/^[0-9\,]+\s((mill\.)|(bill\.)|(thous\.))$/.match(string).nil?
      hash[:i] = "1"
    end
    
    if !/^[a-zA-Z]+$/.match(string).nil?
      hash[:j] = "1"
    end
    
    if !/^[a-zA-Z]+\.$/.match(string).nil?
      hash[:k] = "1"
    end
    
    if !/((km)|(mi)|(miles))/.match(string).nil?
      hash[:l] = "1"
    end
    
    if !/http/.match(string).nil?
      hash[:m] = "1"
    end
    
    if !/\?/.match(string).nil?
      hash[:n] = "1"
    end
    
    if !/\./.match(string).nil?
      hash[:o] = "1"
    end
    
  end
  
  def self.create_line_feature(string)
    features = []
    
    features << "value_of_token="+string
    
    if self.is_number(string.gsub(",",""))
      features << "type=Number"
    else
      features << "type=String"
    end
    
    if !/^\"[^\"]+\"$/.match(string).nil? || !/^\'[^\']+\'$/.match(string).nil?
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
                            
                            val = /\{\{infobox\s*#{infobox_template.name.downcase.gsub(/\s/,'\s').gsub(/\./,'\.')}(.+)((.*)(\{\{(.+)\}\})(.*))*\}\}/m.match(content.downcase)
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
                                                                    
                                  if !@@no_attributes.include?(attr_name) && attr_value != ''
                                    attribute = infobox_template.attributes.where(name: attr_name).first
                                    if attribute.nil?                                    
                                      attribute = infobox_template.attributes.create(name: attr_name)
                                    end
                                    
                                    puts attribute.name
                                    @logstr += attribute.name + "\n"                                  
                                    
                                    attribute_value = AttributeValue.where(article_id: article.id, attribute_id: attribute.id).first
                                    if attribute_value.nil?                                    
                                      AttributeValue.create(article_id: article.id, attribute_id: attribute.id, value: attr_value)                                  
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
    
    count_articles = ((Article.count/3)*2).to_i
    
    Article.update_all("for_test=0","id <= "+count_articles.to_s)
    Article.update_all("for_test=1","id > "+count_articles.to_s)
    
    #File.open("public/log.txt", "w") { |file| file.write @logstr }
  end
  
  ##2
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
  
  ##3
  def self.create_raw_attribute_value
    @avs = AttributeValue.all
    log_str = ""
    @avs.each do |av|
      puts av.article.title + ": " + av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      av.raw_value = av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[[^\]\[]+\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      log_str += av.value + " | " + av.raw_value + "\n"
      av.save
    end
    File.open("public/log_attribute_value.txt", "w") { |file| file.write log_str }
  end
  
  ##4
  def self.find_first_paragraphs    
    infobox_template = InfoboxTemplate.where(name: @@template).first    
    num = 5
    
    infobox_template.articles.all.each do |article|
      content_fixed = article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/m,'<\1>').gsub(/\<p\>(\<a\>(.{2,5})\:[^<]+\<\/a\>\s?)+\<\/p\>/mi, '')      
      while content_fixed.gsub!(/\{\{[^\{\}]*?\}\}/m, ''); end      
      while content_fixed.gsub!(/\{[^\{\}]*?\}/m, ''); end
      while content_fixed.gsub!(/\[\[[^\[\]]*?\]\]/m, ''); end      
      content_fixed = content_fixed.gsub(/\&lt\;ref(.*?)\&gt\;(.*?)\&lt\;\/ref\&gt\;/im,"").gsub(/[\{\}]/,'').gsub(/(\:[0-9]{3,})/,'').gsub(/(\:[a-zA-Z]{3,})/,'')      
      
      pa = Nokogiri::HTML(content_fixed)
      
      count = 1
      str = ''
      pa.css("p").each do |paragraph|
        begin
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
        rescue
        end
      end
      #puts str.gsub('(','( ').gsub(')',' )').gsub(/\s+/,' ').strip
      #sleep(3)
      #save first paragraphs to article
      article.content_plain = str.gsub('(','( ').gsub(')',' )').gsub(/\s+\./,'.').strip
      article.save

      
      puts "===============================================================\n"
    end
  end
  
  ##5
  def self.find_attribute_value_tokens_______
    
    AttributeValueSimilarPattern.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.articles.each do |article|      
      article.attribute_values.where("raw_value != ''").each do |attribute_value|        

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
                  if self.similarity_measure(str.downcase.strip, attribute_value.raw_value.downcase)
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
  
  ##5.1
  def self.write_article_to_file
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/articles`
    `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}`
    
    
    
    infobox_template.articles.each do |article|
      if !File.file?("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
        #code
      
      
        str = ""
        a_parts = article.content_plain.split("\n")
        if !a_parts.nil?
          
          a_parts.each_with_index do |paragraph,p_index|
            p_parts = paragraph.split(/(.{4,}?[\.\?\!]) ?/).reject! { |c| c.empty? }
            
            if !p_parts.nil?
              p_parts.each_with_index do |sentence,s_index|
                
                if sentence.gsub(/\s+/,' ').strip.length > 3
                  str += sentence.gsub(/\s+/,' ').strip + "\n"
                end                
                
              end
            end
            
            str += "\n"
          end
        end
        puts article.title
        File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write  str }
        
        #POS tagging file
        `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged`
        `java -jar bin/POSFILE.jar public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt`
        
      end
    end
    
  end
  
  ##5.2
  def self.create_label_for_tokens
    #AttributeValueSimilarPattern.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
        
      if !File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt")
      
        count_tpm_file = 0
        infobox_template.articles.each do |article|
          if File.file?("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
          
              tag_file = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
              article_file = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
              
              attribute_value = AttributeValue.where("raw_value != ''").where(article_id: article.id).where(attribute_id: attribute.id).first
              
              
              if !attribute_value.nil?
                att_parts = attribute_value.raw_value.gsub(/\s+/,' ').split(" ")
                
                paragraph = 1
                tokens_per_p = []
                sentence = 1
                word = 1
                tokens = []
                test_tokens = []
                has_value = 0
                training_str = ""            
                while(line = article_file.gets)
                  tag_line = tag_file.gets
                            
                  if line.strip != ''
                    w_parts = line.split(" ")
                    t_parts = tag_line.split(" ")
                    
                    value_count = 0
                    w_parts.each_with_index do |word,w_index|
                      
                      hash = {}
                      
                      hash[:p] = t_parts[w_index]
                      
                      if value_count == 0
                        
                        #word is not value
                        hash[:label] = "NIL"
                        
                        str = ""
                        (0..(att_parts.count-1)).each do |i|
                          str += w_parts[w_index+i] + " " if !w_parts[w_index+i].nil?
                        end
                        
                        #get value and check firest token of value
                        if self.similarity_measure(str.downcase.strip, attribute_value.raw_value.downcase)
                          hash[:label] = "VAL"
                          
                          value = str
                          #save value
                          
                          exsit = AttributeValueSimilarPattern.where(infobox_template_id: infobox_template.id,
                                                                                       article_id: attribute_value.article_id,
                                                                                       attribute_id: attribute_value.attribute_id).first
                          
                          puts exsit.nil?
                          if exsit.nil?
                            avsp = attribute_value.attribute_value_similar_patterns.create(infobox_template_id: infobox_template.id,
                                                                                       article_id: attribute_value.article_id,
                                                                                       attribute_id: attribute_value.attribute_id,
                                                                                       value: value.strip)
                          end
                          
                          
                          
                          value_count = att_parts.count-1
                          
                          has_value = 1
                          #puts value_count.to_s + ": " + word + " // " + attribute_value.raw_value.downcase
                        end
                      else #remain tokens of value
                        hash[:label] = "VAL"
                        
                        value_count -= 1
    
                        #puts value_count.to_s + ": " + word + " // " + attribute_value.raw_value.downcase
                      end
                      
                      
                      #result
                      self.create_hash_feature(hash,word)
                      
                      hash[:small_token] = "1" if word.length < 10
                      #hash[:long_paragraph] = "1" if sentence > 2
                      hash[:paragraph] = paragraph.to_s
                      hash[:sentence] = sentence.to_s
                      hash[:word] = (w_index+1).to_s
                      
                      tokens_per_p << hash
                      
                      #if hash[:label] == "VAL"
                      #  puts hash[:a]
                      #  sleep(1)
                      #end
                      
              
                      #train_line += "\t" + "small_token=1" if word.length < 10
                      #train_line += "\t" + "long_paragraph=1" if pattern.long_paragraph == 1
                      #train_line += "\t" + "paragraph=" + pattern.paragraph.to_s
                      #train_line += "\t" + "sentence=" + pattern.sentence.to_s
                      #train_line += "\t" + "word=" + pattern.word.to_s
                      
                    end
                    
                  else
                    if sentence > 2
                      tokens_per_p.each_with_index do |token,t_index|
                        tokens_per_p[t_index][:long_paragraph] = "1"
                      end
                    end
                    
                    if article.for_test == 0
                      tokens += tokens_per_p
                    else
                      #test_tokens += tokens_per_p
                    end
                    
                      
                    
                    tokens_per_p = []
                    sentence = 0
                    paragraph += 1
                  end
                  
                  #tokens_per_p << {:label => "newline"}
                  sentence += 1
                end
                
                
                ##create training 
                if has_value == 1
                  
                  ####write training and testing crf file
                  tokens.each_with_index do |token,t_index|
                    #if token[:label] != "newline"
                      
                    
                      #training_str = ""
                      ss = ""
                      ss += token[:label] + "\t"
                      
                      
                      (1..5).each do |j|
                        th = t_index - j
                        if th >= 0
                          ss += "w[-" + j.to_s + "]k[a]=" + tokens[th][:a] + "\t" if !tokens[th][:a].nil?
                          ss += "w[-" + j.to_s + "]k[b]=" + tokens[th][:b] + "\t" if !tokens[th][:b].nil?
                          ss += "w[-" + j.to_s + "]k[c]=" + tokens[th][:c] + "\t" if !tokens[th][:c].nil?
                          ss += "w[-" + j.to_s + "]k[d]=" + tokens[th][:d] + "\t" if !tokens[th][:d].nil?
                          ss += "w[-" + j.to_s + "]k[e]=" + tokens[th][:e] + "\t" if !tokens[th][:e].nil?
                          ss += "w[-" + j.to_s + "]k[f]=" + tokens[th][:f] + "\t" if !tokens[th][:f].nil?
                          ss += "w[-" + j.to_s + "]k[g]=" + tokens[th][:g] + "\t" if !tokens[th][:g].nil?
                          ss += "w[-" + j.to_s + "]k[h]=" + tokens[th][:h] + "\t" if !tokens[th][:h].nil?
                          ss += "w[-" + j.to_s + "]k[i]=" + tokens[th][:i] + "\t" if !tokens[th][:i].nil?
                          ss += "w[-" + j.to_s + "]k[j]=" + tokens[th][:j] + "\t" if !tokens[th][:j].nil?
                          ss += "w[-" + j.to_s + "]k[k]=" + tokens[th][:k] + "\t" if !tokens[th][:k].nil?
                          ss += "w[-" + j.to_s + "]k[l]=" + tokens[th][:l] + "\t" if !tokens[th][:l].nil?
                          ss += "w[-" + j.to_s + "]k[m]=" + tokens[th][:m] + "\t" if !tokens[th][:m].nil?
                          ss += "w[-" + j.to_s + "]k[n]=" + tokens[th][:n] + "\t" if !tokens[th][:n].nil?
                          ss += "w[-" + j.to_s + "]k[o]=" + tokens[th][:o] + "\t" if !tokens[th][:o].nil?
                          ss += "w[-" + j.to_s + "]k[p]=" + tokens[th][:p] + "\t" if !tokens[th][:p].nil?
                        end            
                      end
                      
                      
                      ss += "w[0]k[a]=" + token[:a] + "\t" if !token[:a].nil?
                      ss += "w[0]k[b]=" + token[:b] + "\t" if !token[:b].nil?
                      ss += "w[0]k[c]=" + token[:c] + "\t" if !token[:c].nil?
                      ss += "w[0]k[d]=" + token[:d] + "\t" if !token[:d].nil?
                      ss += "w[0]k[e]=" + token[:e] + "\t" if !token[:e].nil?
                      ss += "w[0]k[f]=" + token[:f] + "\t" if !token[:f].nil?
                      ss += "w[0]k[g]=" + token[:g] + "\t" if !token[:g].nil?
                      ss += "w[0]k[h]=" + token[:h] + "\t" if !token[:h].nil?
                      ss += "w[0]k[i]=" + token[:i] + "\t" if !token[:i].nil?
                      ss += "w[0]k[j]=" + token[:j] + "\t" if !token[:j].nil?
                      ss += "w[0]k[k]=" + token[:k] + "\t" if !token[:k].nil?
                      ss += "w[0]k[l]=" + token[:l] + "\t" if !token[:l].nil?
                      ss += "w[0]k[m]=" + token[:m] + "\t" if !token[:m].nil?
                      ss += "w[0]k[n]=" + token[:n] + "\t" if !token[:n].nil?
                      ss += "w[0]k[o]=" + token[:o] + "\t" if !token[:o].nil?
                      ss += "w[0]k[p]=" + token[:p] + "\t" if !token[:p].nil?
                      
                      ss += "w[0]k[c1]=" + token[:long_paragraph] + "\t" if !token[:long_paragraph].nil?
                      ss += "w[0]k[c2]=" + token[:small_token] + "\t" if !token[:small_token].nil?
                      ss += "w[0]k[c3]=" + token[:paragraph] + "\t" if !token[:paragraph].nil?
                      ss += "w[0]k[c4]=" + token[:sentence] + "\t" if !token[:sentence].nil?
                      ss += "w[0]k[c5]=" + token[:word] + "\t" if !token[:word].nil?
                      
                      
                      (1..5).each do |j|
                        th = t_index + j
                        if th < tokens.count
                          ss += "w[" + j.to_s + "]k[a]=" + tokens[th][:a] + "\t" if !tokens[th][:a].nil?
                          ss += "w[" + j.to_s + "]k[b]=" + tokens[th][:b] + "\t" if !tokens[th][:b].nil?
                          ss += "w[" + j.to_s + "]k[c]=" + tokens[th][:c] + "\t" if !tokens[th][:c].nil?
                          ss += "w[" + j.to_s + "]k[d]=" + tokens[th][:d] + "\t" if !tokens[th][:d].nil?
                          ss += "w[" + j.to_s + "]k[e]=" + tokens[th][:e] + "\t" if !tokens[th][:e].nil?
                          ss += "w[" + j.to_s + "]k[f]=" + tokens[th][:f] + "\t" if !tokens[th][:f].nil?
                          ss += "w[" + j.to_s + "]k[g]=" + tokens[th][:g] + "\t" if !tokens[th][:g].nil?
                          ss += "w[" + j.to_s + "]k[h]=" + tokens[th][:h] + "\t" if !tokens[th][:h].nil?
                          ss += "w[" + j.to_s + "]k[i]=" + tokens[th][:i] + "\t" if !tokens[th][:i].nil?
                          ss += "w[" + j.to_s + "]k[j]=" + tokens[th][:j] + "\t" if !tokens[th][:j].nil?
                          ss += "w[" + j.to_s + "]k[k]=" + tokens[th][:k] + "\t" if !tokens[th][:k].nil?
                          ss += "w[" + j.to_s + "]k[l]=" + tokens[th][:l] + "\t" if !tokens[th][:l].nil?
                          ss += "w[" + j.to_s + "]k[m]=" + tokens[th][:m] + "\t" if !tokens[th][:m].nil?
                          ss += "w[" + j.to_s + "]k[n]=" + tokens[th][:n] + "\t" if !tokens[th][:n].nil?
                          ss += "w[" + j.to_s + "]k[o]=" + tokens[th][:o] + "\t" if !tokens[th][:o].nil?
                          ss += "w[" + j.to_s + "]k[p]=" + tokens[th][:p] + "\t" if !tokens[th][:p].nil?
                        end            
                      end
                      
                      
                      
                      training_str += ss.strip + "\n"
                    #else
                    #  training_str += "\n"
                    #end
                    
                    #puts ss
                  end
                  training_str += "\n"
                end
                
                ##insert article to training file
                if training_str.strip != ''
                  `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
                  
                  File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train_#{count_tpm_file.to_s}.tpm", "w") { |file| file.write  training_str }
                  
                  count_tpm_file += 1
                end
              end
          end
          
        end
        
        #merge tpm file
        `cat public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/*.tpm > public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt`
        `rm public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/*.tpm`
        
        #write file
        ###
        #if training_str.strip != ''
        #  `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
        #  File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt", "w") { |file| file.write  training_str }
        #end
    
      end
    
    end
    
    
  end
  
  ##5.3
  def self.create_crf_test_file
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test`
    
    #infobox_template.attributes.where(status: 1).each do |attribute|
    #    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
      
      
        training_str = ""
        infobox_template.articles.where(for_test: 1).each do |article|
          
          if File.file?("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
          
            tag_file = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/tagged/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
            article_file = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
            
            
              
              paragraph = 1
              tokens_per_p = []
              sentence = 1
              word = 1
              tokens = []
              test_tokens = []
              has_value = 0
              while(line = article_file.gets)
                tag_line = tag_file.gets
                          
                if line.strip != ''
                  w_parts = line.split(" ")
                  t_parts = tag_line.split(" ")
                  
                  value_count = 0
                  w_parts.each_with_index do |word,w_index|
                    
                    hash = {}
                    
                    hash[:p] = t_parts[w_index]
  
                    #result
                    self.create_hash_feature(hash,word)
                    
                    hash[:small_token] = "1" if word.length < 10
                    #hash[:long_paragraph] = "1" if sentence > 2
                    hash[:paragraph] = paragraph.to_s
                    hash[:sentence] = sentence.to_s
                    hash[:word] = (w_index+1).to_s
                    
                    tokens_per_p << hash
            
                   
                  end
                  
                else
                  if sentence > 2
                    tokens_per_p.each_with_index do |token,t_index|
                      tokens_per_p[t_index][:long_paragraph] = "1"
                    end
                  end
                  
                  if article.for_test == 0
                    tokens += tokens_per_p
                  else
                    test_tokens += tokens_per_p
                  end
                  
                    
                  
                  tokens_per_p = []
                  sentence = 0
                  paragraph += 1
                end
                #tokens_per_p << {:label => "newline"}
                sentence += 1
              end
            
            
              ####write training and testing crf file
              testing_string = "";
              tokens = test_tokens
              tokens.each_with_index do |token,t_index|
                #if token[:label] != "newline"
                  #training_str = ""
                  ss = ""
                  
                  
                  (1..5).each do |j|
                    th = t_index - j
                    if th >= 0
                      ss += "w[-" + j.to_s + "]k[a]=" + tokens[th][:a] + "\t" if !tokens[th][:a].nil?
                      ss += "w[-" + j.to_s + "]k[b]=" + tokens[th][:b] + "\t" if !tokens[th][:b].nil?
                      ss += "w[-" + j.to_s + "]k[c]=" + tokens[th][:c] + "\t" if !tokens[th][:c].nil?
                      ss += "w[-" + j.to_s + "]k[d]=" + tokens[th][:d] + "\t" if !tokens[th][:d].nil?
                      ss += "w[-" + j.to_s + "]k[e]=" + tokens[th][:e] + "\t" if !tokens[th][:e].nil?
                      ss += "w[-" + j.to_s + "]k[f]=" + tokens[th][:f] + "\t" if !tokens[th][:f].nil?
                      ss += "w[-" + j.to_s + "]k[g]=" + tokens[th][:g] + "\t" if !tokens[th][:g].nil?
                      ss += "w[-" + j.to_s + "]k[h]=" + tokens[th][:h] + "\t" if !tokens[th][:h].nil?
                      ss += "w[-" + j.to_s + "]k[i]=" + tokens[th][:i] + "\t" if !tokens[th][:i].nil?
                      ss += "w[-" + j.to_s + "]k[j]=" + tokens[th][:j] + "\t" if !tokens[th][:j].nil?
                      ss += "w[-" + j.to_s + "]k[k]=" + tokens[th][:k] + "\t" if !tokens[th][:k].nil?
                      ss += "w[-" + j.to_s + "]k[l]=" + tokens[th][:l] + "\t" if !tokens[th][:l].nil?
                      ss += "w[-" + j.to_s + "]k[m]=" + tokens[th][:m] + "\t" if !tokens[th][:m].nil?
                      ss += "w[-" + j.to_s + "]k[n]=" + tokens[th][:n] + "\t" if !tokens[th][:n].nil?
                      ss += "w[-" + j.to_s + "]k[o]=" + tokens[th][:o] + "\t" if !tokens[th][:o].nil?
                      ss += "w[-" + j.to_s + "]k[p]=" + tokens[th][:p] + "\t" if !tokens[th][:p].nil?
                    end            
                  end
                  
                  
                  ss += "w[0]k[a]=" + token[:a] + "\t" if !token[:a].nil?
                  ss += "w[0]k[b]=" + token[:b] + "\t" if !token[:b].nil?
                  ss += "w[0]k[c]=" + token[:c] + "\t" if !token[:c].nil?
                  ss += "w[0]k[d]=" + token[:d] + "\t" if !token[:d].nil?
                  ss += "w[0]k[e]=" + token[:e] + "\t" if !token[:e].nil?
                  ss += "w[0]k[f]=" + token[:f] + "\t" if !token[:f].nil?
                  ss += "w[0]k[g]=" + token[:g] + "\t" if !token[:g].nil?
                  ss += "w[0]k[h]=" + token[:h] + "\t" if !token[:h].nil?
                  ss += "w[0]k[i]=" + token[:i] + "\t" if !token[:i].nil?
                  ss += "w[0]k[j]=" + token[:j] + "\t" if !token[:j].nil?
                  ss += "w[0]k[k]=" + token[:k] + "\t" if !token[:k].nil?
                  ss += "w[0]k[l]=" + token[:l] + "\t" if !token[:l].nil?
                  ss += "w[0]k[m]=" + token[:m] + "\t" if !token[:m].nil?
                  ss += "w[0]k[n]=" + token[:n] + "\t" if !token[:n].nil?
                  ss += "w[0]k[o]=" + token[:o] + "\t" if !token[:o].nil?
                  ss += "w[0]k[p]=" + token[:p] + "\t" if !token[:p].nil?
                  
                  ss += "w[0]k[c1]=" + token[:long_paragraph] + "\t" if !token[:long_paragraph].nil?
                  ss += "w[0]k[c2]=" + token[:small_token] + "\t" if !token[:small_token].nil?
                  ss += "w[0]k[c3]=" + token[:paragraph] + "\t" if !token[:paragraph].nil?
                  ss += "w[0]k[c4]=" + token[:sentence] + "\t" if !token[:sentence].nil?
                  ss += "w[0]k[c5]=" + token[:word] + "\t" if !token[:word].nil?
                  
                  
                  (1..5).each do |j|
                    th = t_index + j
                    if th < tokens.count
                      ss += "w[" + j.to_s + "]k[a]=" + tokens[th][:a] + "\t" if !tokens[th][:a].nil?
                      ss += "w[" + j.to_s + "]k[b]=" + tokens[th][:b] + "\t" if !tokens[th][:b].nil?
                      ss += "w[" + j.to_s + "]k[c]=" + tokens[th][:c] + "\t" if !tokens[th][:c].nil?
                      ss += "w[" + j.to_s + "]k[d]=" + tokens[th][:d] + "\t" if !tokens[th][:d].nil?
                      ss += "w[" + j.to_s + "]k[e]=" + tokens[th][:e] + "\t" if !tokens[th][:e].nil?
                      ss += "w[" + j.to_s + "]k[f]=" + tokens[th][:f] + "\t" if !tokens[th][:f].nil?
                      ss += "w[" + j.to_s + "]k[g]=" + tokens[th][:g] + "\t" if !tokens[th][:g].nil?
                      ss += "w[" + j.to_s + "]k[h]=" + tokens[th][:h] + "\t" if !tokens[th][:h].nil?
                      ss += "w[" + j.to_s + "]k[i]=" + tokens[th][:i] + "\t" if !tokens[th][:i].nil?
                      ss += "w[" + j.to_s + "]k[j]=" + tokens[th][:j] + "\t" if !tokens[th][:j].nil?
                      ss += "w[" + j.to_s + "]k[k]=" + tokens[th][:k] + "\t" if !tokens[th][:k].nil?
                      ss += "w[" + j.to_s + "]k[l]=" + tokens[th][:l] + "\t" if !tokens[th][:l].nil?
                      ss += "w[" + j.to_s + "]k[m]=" + tokens[th][:m] + "\t" if !tokens[th][:m].nil?
                      ss += "w[" + j.to_s + "]k[n]=" + tokens[th][:n] + "\t" if !tokens[th][:n].nil?
                      ss += "w[" + j.to_s + "]k[o]=" + tokens[th][:o] + "\t" if !tokens[th][:o].nil?
                      ss += "w[" + j.to_s + "]k[p]=" + tokens[th][:p] + "\t" if !tokens[th][:p].nil?
                    end            
                  end
                  
                  
                  
                  testing_string += ss.strip + "\n"
                #else
                #  testing_string += "\n"
                #end
                
              end
              
              File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write  testing_string } if testing_string.strip != ''
          
          end
          
        end
    
        #write file
        ###
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt", "w") { |file| file.write  training_str } if training_str.strip != ''
    
    #end
    
    
  end
  
  ##6####################
  def self.create_crf_training_data   
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train`
    
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
          #train_line += "\t" + "small_token=1" if word.length < 10
          #train_line += "\t" + "long_paragraph=1" if pattern.long_paragraph == 1
          #train_line += "\t" + "paragraph=" + pattern.paragraph.to_s
          #train_line += "\t" + "sentence=" + pattern.sentence.to_s
          #train_line += "\t" + "word=" + pattern.word.to_s
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
        `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt", "w") { |file| file.write  train_lines }
      end
      
    end
    
  end
  
  ##7
  def self.training_crf
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt") && !File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/crf.model")
        `~/local/bin/crfsuite learn -m ~/rails-apps/ipopular/public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/crf.model  ~/rails-apps/ipopular/public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/train.txt`
      end
    end
    
  end
  
  ##8########################
  def self.create_crf_testing_data   
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test`
    
    infobox_template.articles.where(for_test:1).each do |article|
      
      if !File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")

        a_parts = article.content_plain.split("\n")
        
        test_sentences = ""
        if !a_parts.nil?
          a_parts.each_with_index do |paragraph,p_index|
            p_parts = paragraph.split(/(.{4,}?[\.\?\!]) ?/).reject! { |c| c.empty? }
            
            if !p_parts.nil?
              p_parts.each_with_index do |sentence,s_index|
                
                full_string = sentence.gsub(/\s+/,' ').strip
                
                tags = `java -jar bin/POS.jar "#{full_string.strip.gsub(/[\,\.\!\?\"\']/,'')}"`
                
                puts tags.split(" ").count.to_s + full_string.split(" ").count.to_s
                
                tags = tags.split(" ")
                
                #long_p = 0
                #if p_parts.count > 2
                #  long_p = 1
                #end
                
                test_sentence = ""
                s_parts = full_string.split(" ")
                s_parts.each_with_index do |word,w_index|
                
                  tag = tags[w_index]
                  test_sentence += self.create_line_feature(word.strip).join("\t") + "\t" + "POS=" + tag.to_s
                  #test_sentence += "\t" + "small_token=1" if word.length < 10
                  #test_sentence += "\t" + "long_paragraph=1" if pattern.long_paragraph == 1
                  #test_sentence += "\t" + "paragraph=" + p_index.to_s
                  #test_sentence += "\t" + "sentence=" + s_index.to_s
                  #test_sentence += "\t" + "word=" + w_index.to_s
                  test_sentence += "\n"
                  
                end
                puts test_sentence
                test_sentences += test_sentence + "\n" if test_sentence.strip != ''
              end
            end
          end
        end
        
        #{article.title.gsub(/[\s\&\'\,]/,'_')}.txt puts test_sentences
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write  test_sentences } if test_sentences.strip != ''
      else
        puts "exsit"
      end
    end
    
  end
    
  ##9 get attribute values from test article
  def self.get_values_from_test_article    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result`

    infobox_template.attributes.where(status: 1).each do |attribute|
      if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/crf.model")
        `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}`
        infobox_template.articles.where(for_test:1).each do |article|
          if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,]/,'_')}.txt")
            
            result = `~/local/bin/crfsuite tag -m public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/crf.model  public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt`
            
            if !result.nil?
              File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write  result }
            end            
            
          end
        end
        
      end
    end
  end
  
  ##10
  def self.get_results
    AttributeTestValue.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.articles.where(for_test:1).each do |article|
      if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
        a_file = File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")      
        a_array = []
        while(a_line = a_file.gets)
          a_array << a_line.to_s
        end

        infobox_template.attributes.where(status: 1).each do |attribute|
          if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
            att_file = File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
            att_index = 0
            result = ""
            finded = false
            while(att_line = att_file.gets)
              while att_line.strip != '' && a_array[att_index].strip == ''
                att_index += 1
              end
                att_line = att_line.strip
                if att_line == 'VAL'
                  result_line = a_array[att_index]
                  
                  puts "##"+att_index.to_s
                  puts "##"+article.title
                  
                  result += /w\[0\]k\[a\]\=([^\t]+)\t/.match(result_line)[1] + " "
                  finded = true
                end
                if att_line == 'NIL' && finded
                  break
                end
              
              
              att_index += 1
            end

            if result.gsub('"','').strip != ""
              puts result.strip
              
              exsit = AttributeTestValue.where(article_id: article.id, attribute_id: attribute.id).first
              
              if exsit.nil?
                AttributeTestValue.create(article_id: article.id,
                                        attribute_id: attribute.id,
                                        value: result.strip
                                      )
              end
            end
              

          end

          #if File.file?("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
          #  
          #  result = `~/local/bin/crfsuite tag -m public/crf/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/\']+/,'_')}/crf.model  public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt`
          #  
          #  if !result.nil?
          #    File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/test/result/#{attribute.name.gsub(/[\s\/\']+/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write  result }
          #  end            
          #  
          #end
        end
      end
    end
  end
  
  ##11
  def self.calculate_result
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/result`
    `mkdir public/result/#{infobox_template.name.gsub(/\s/,'_')}`
    
    
    #result for each attribute
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      
      
      correct = 0
      wrong = 0
      str = ""
      count = 1
      result_str = ""
      AttributeTestValue.where(attribute_id: attribute.id).all.each do |test_value|
        value = AttributeValue.where(article_id: test_value.article_id, attribute_id: test_value.attribute_id).first
        avsp = AttributeValueSimilarPattern.where(article_id: test_value.article_id, attribute_id: test_value.attribute_id).first
        
        if !value.nil? && !avsp.nil? 
          if self.similarity_measure(value.raw_value.downcase, test_value.value.downcase)
            str += count.to_s + "\t" + "true" + "\t" +  test_value.attribute.name + ": " + value.raw_value + " / " + test_value.value + "\n"
            correct += 1
          else
            str += count.to_s + "\t" + "false" + "\t" +  test_value.attribute.name + ": " + value.raw_value + " / " + test_value.value + "\n"
            wrong += 1
          end
        else
          str += count.to_s + "\t" + "null" + "\t" +  test_value.attribute.name + ": ..... / " + test_value.value + "\n"
        end
        
        count += 1
      end
      
      AttributeValue.joins(:article).where("articles.for_test=1").where(attribute_id: attribute.id).each do |value|
        test_value = AttributeTestValue.joins(:attribute).where("attributes.high_rate=1").where(article_id: value.article_id).where(attribute_id: value.attribute_id).first
        avsp = AttributeValueSimilarPattern.where(article_id: value.article_id).where(attribute_id: value.attribute_id).first
        
        if !avsp.nil?
          
          if test_value.nil?
            str += count.to_s + "\t" + "null" + "\t" +  value.attribute.name + ": " + value.raw_value.to_s + " / ..........\n"
            count += 1
          end
        
        end

      end
        
        
        total = AttributeValueSimilarPattern.joins(:article).where("articles.for_test=1").where(attribute_id: attribute.id).count("CONCAT(article_id,'---',attribute_id)",distinct: true)
        found = AttributeTestValue.where(attribute_id: attribute.id).count
    
        first_line = "Found: " + found.to_s + "\n"      
        first_line = "Found Not Null: " + (correct+wrong).to_s + "\n"
        first_line += "Correct: " + correct.to_s + "\n"
        first_line += "Wrong: " + wrong.to_s + "\n"
        first_line += "Total: " + total.to_s + "\n-----------\n"
        first_line += "precision: " + (correct.to_f/(correct.to_f+wrong.to_f)).to_s + "\n" if correct+wrong > 0
        first_line += "recall: " + (correct.to_f/total.to_f).to_s + "\n" if total > 0
        first_line += "\n\n\n\n"
        
        result_str += first_line
        
        
        if correct+wrong > 0 && (correct.to_f/(correct.to_f+wrong.to_f)) >= 0.75
          attribute.high_rate = 1
        else
          attribute.high_rate = 0
        end
        attribute.save
        
        File.open("public/result/#{infobox_template.name.gsub(/\s/,'_')}/#{attribute.name.gsub(/[\s\/\']+/,'_')}.txt", "w") { |file| file.write  result_str + str}
      
    end
    
    
    
    
    ##Result for all
    correct = 0
    wrong = 0
    str = ""
    count = 1
    AttributeTestValue.joins(:attribute).where("attributes.high_rate=1").each do |test_value|
      value = AttributeValue.where(article_id: test_value.article_id).where(attribute_id: test_value.attribute_id).first
      avsp = AttributeValueSimilarPattern.where(article_id: test_value.article_id).where(attribute_id: test_value.attribute_id).first
      
      if !value.nil? && !avsp.nil? 
        if self.similarity_measure(value.raw_value.downcase, test_value.value.downcase)
          str += count.to_s + "\t" + "true" + "\t" +  test_value.attribute.name + ": " + value.raw_value + " / " + test_value.value + "\n"
          correct += 1
        else
          str += count.to_s + "\t" + "false" + "\t" +  test_value.attribute.name + ": " + value.raw_value + " / " + test_value.value + "\n"
          wrong += 1
        end
      else
        str += count.to_s + "\t" + "null" + "\t" +  test_value.attribute.name + ": ..... / " + test_value.value + "\n"
      end
      
      count += 1
    end
    
    AttributeValue.joins(:article).where("articles.for_test=1").each do |value|
      test_value = AttributeTestValue.joins(:attribute).where("attributes.high_rate=1").where(article_id: value.article_id).where(attribute_id: value.attribute_id).first
      avsp = AttributeValueSimilarPattern.where(article_id: value.article_id).where(attribute_id: value.attribute_id).first
      
      
      if !avsp.nil?
        
        if test_value.nil?
          str += count.to_s + "\t" + "null" + "\t" +  value.attribute.name + ": " + value.raw_value.to_s + " / ..........\n"
          count += 1
        end
      
      
      
      end
    
      
    end
    
    artilce_count = infobox_template.articles.count.to_s
    artilce_test = infobox_template.articles.where(for_test: 0).count.to_s
    artilce_train = infobox_template.articles.where(for_test: 1).count.to_s
    
    attribute_count = infobox_template.attributes.count.to_s
    attribute_count_for_test = infobox_template.attributes.where(status: 1).count.to_s
    attribute_count_high_rate = infobox_template.attributes.where(status: 1).where(high_rate: 1).count.to_s
    
    total = AttributeValueSimilarPattern.joins(:article).where("articles.for_test=1").count("CONCAT(article_id,'---',attribute_id)",distinct: true)
    found = AttributeTestValue.count
    
    first_line = "Total articles: " + artilce_count.to_s + "\n"
    first_line += "Articles for test: " + artilce_test.to_s + "\n"
    first_line += "Articles for train: " + artilce_train.to_s + "\n"
    first_line += "Total attributes: " + attribute_count.to_s + "\n"
    first_line += "Attributes with high occurrences: " + attribute_count_for_test.to_s + "/" + attribute_count.to_s + "\n"
    first_line += "Attributes with high precision: " + attribute_count_high_rate.to_s + "/" + attribute_count_for_test.to_s + "\n------------\n"
    
    first_line += "Found: " + found.to_s + "\n"
    first_line += "Found Not Null: " + (correct+wrong).to_s + "\n"
    first_line += "Correct: " + correct.to_s + "\n"
    first_line += "Wrong: " + wrong.to_s + "\n"
    first_line += "Total: " + total.to_s + "\n-----------\n"
    first_line += "precision: " + (correct.to_f/(correct.to_f+wrong.to_f)).to_s + "\n" if correct+wrong > 0
    first_line += "recall: " + (correct.to_f/total.to_f).to_s + "\n" if total > 0
    first_line += "\n\n\n"
    File.open("public/result/#{infobox_template.name.gsub(/\s/,'_')}/all.txt", "w") { |file| file.write  first_line + str}
    
  end
  
  
  
  ############
  def self.run_all
    ###1
    #self.import(12168)
    #self.write_log("######### 1 import")
    #
    ###2
    #self.set_attribute_status
    #self.write_log("######### 2 find_first_paragraphs")
    #    
    ###3
    #self.create_raw_attribute_value
    #self.write_log("######### 3 create_raw_attribute_value")
    #
    ###4
    #self.find_first_paragraphs
    #self.write_log("######### 4 find_first_paragraphs")
    #
    ###5.1
    #self.write_article_to_file
    #self.write_log("######### 5.1 write_article_to_file")
    #
    ##5.2
    self.create_label_for_tokens
    self.write_log("######### 5.2 create_label_for_tokens")
    
    ##5.3
    self.create_crf_test_file
    self.write_log("######### 5.3 create_crf_test_file")
    
    ##7
    self.training_crf
    self.write_log("######### 7 training_crf")
      
    ##9
    self.get_values_from_test_article
    self.write_log("######### 9 get_values_from_test_article")
    
    ##10
    self.get_results
    self.write_log("######### 10 get_results")
    
    ##11
    self.calculate_result
    self.write_log("######### 11 calculate_result")
        
  end
  
end
