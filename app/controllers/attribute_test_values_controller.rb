class AttributeTestValuesController < ApplicationController
  before_action :set_attribute_test_value, only: [:show, :edit, :update, :destroy]

  # GET /attribute_test_values
  # GET /attribute_test_values.json
  def index
    @attribute_test_values = AttributeTestValue.all
  end

  # GET /attribute_test_values/1
  # GET /attribute_test_values/1.json
  def show
  end

  # GET /attribute_test_values/new
  def new
    @attribute_test_value = AttributeTestValue.new
  end

  # GET /attribute_test_values/1/edit
  def edit
  end

  # POST /attribute_test_values
  # POST /attribute_test_values.json
  def create
    @attribute_test_value = AttributeTestValue.new(attribute_test_value_params)

    respond_to do |format|
      if @attribute_test_value.save
        format.html { redirect_to @attribute_test_value, notice: 'Attribute test value was successfully created.' }
        format.json { render action: 'show', status: :created, location: @attribute_test_value }
      else
        format.html { render action: 'new' }
        format.json { render json: @attribute_test_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attribute_test_values/1
  # PATCH/PUT /attribute_test_values/1.json
  def update
    respond_to do |format|
      if @attribute_test_value.update(attribute_test_value_params)
        format.html { redirect_to @attribute_test_value, notice: 'Attribute test value was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @attribute_test_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attribute_test_values/1
  # DELETE /attribute_test_values/1.json
  def destroy
    @attribute_test_value.destroy
    respond_to do |format|
      format.html { redirect_to attribute_test_values_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attribute_test_value
      @attribute_test_value = AttributeTestValue.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attribute_test_value_params
      params[:attribute_test_value]
    end
end
