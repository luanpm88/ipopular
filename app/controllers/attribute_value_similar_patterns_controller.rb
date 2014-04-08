class AttributeValueSimilarPatternsController < ApplicationController
  before_action :set_attribute_value_similar_pattern, only: [:show, :edit, :update, :destroy]

  # GET /attribute_value_similar_patterns
  # GET /attribute_value_similar_patterns.json
  def index
    @attribute_value_similar_patterns = AttributeValueSimilarPattern.all
  end

  # GET /attribute_value_similar_patterns/1
  # GET /attribute_value_similar_patterns/1.json
  def show
  end

  # GET /attribute_value_similar_patterns/new
  def new
    @attribute_value_similar_pattern = AttributeValueSimilarPattern.new
  end

  # GET /attribute_value_similar_patterns/1/edit
  def edit
  end

  # POST /attribute_value_similar_patterns
  # POST /attribute_value_similar_patterns.json
  def create
    @attribute_value_similar_pattern = AttributeValueSimilarPattern.new(attribute_value_similar_pattern_params)

    respond_to do |format|
      if @attribute_value_similar_pattern.save
        format.html { redirect_to @attribute_value_similar_pattern, notice: 'Attribute value similar pattern was successfully created.' }
        format.json { render action: 'show', status: :created, location: @attribute_value_similar_pattern }
      else
        format.html { render action: 'new' }
        format.json { render json: @attribute_value_similar_pattern.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attribute_value_similar_patterns/1
  # PATCH/PUT /attribute_value_similar_patterns/1.json
  def update
    respond_to do |format|
      if @attribute_value_similar_pattern.update(attribute_value_similar_pattern_params)
        format.html { redirect_to @attribute_value_similar_pattern, notice: 'Attribute value similar pattern was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @attribute_value_similar_pattern.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attribute_value_similar_patterns/1
  # DELETE /attribute_value_similar_patterns/1.json
  def destroy
    @attribute_value_similar_pattern.destroy
    respond_to do |format|
      format.html { redirect_to attribute_value_similar_patterns_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attribute_value_similar_pattern
      @attribute_value_similar_pattern = AttributeValueSimilarPattern.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attribute_value_similar_pattern_params
      params.require(:attribute_value_similar_pattern).permit(:attribute_value_id, :value, :paragraph, :sentence, :word)
    end
end
