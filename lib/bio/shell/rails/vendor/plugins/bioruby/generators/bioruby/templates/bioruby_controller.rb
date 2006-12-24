class BiorubyController < ApplicationController

  HIDE_METHODS = Object.methods

  HIDE_MODULES = [
    WEBrick, Base64::Deprecated, Base64, PP::ObjectMixin,
  ]

  def evaluate
    begin
      @script = params[:script].strip

      # write out to history
      Bio::Shell.store_history(@script)

      # evaluate ruby script
      @result = eval(@script, Bio::Shell.cache[:binding])

      # *TODO* need to handle with output of print/puts/p/pp etc. here
      @output = nil
    rescue
      @result = $!
      @output = nil
    end

    @number = Bio::Shell.cache[:results].store(@script, @result, @output)

    render :update do |page|
      page.insert_html :after, "console", :partial => "result"
      page.replace_html "variables", :partial => "variables"
      page.hide "methods_#{@number}"
      page.hide "classes_#{@number}"
      page.hide "modules_#{@number}"
    end
  end

  def list_methods
    number = params[:number].to_i
    script, result, output = Bio::Shell.cache[:results].restore(number)
    @class = result.class
    @methods = result.methods - HIDE_METHODS

    render :update do |page|
      page.replace_html "methods_#{number}", :partial => "methods"
      page.visual_effect :toggle_blind, "methods_#{number}", :duration => 0.5
    end
  end

  def list_classes
    number = params[:number].to_i
    script, result, output = Bio::Shell.cache[:results].restore(number)
    class_name = result.class
    @class = class_name
    @classes = []
    loop do
      @classes.unshift(class_name)
      if class_name == Object
        break
      else
        class_name = class_name.superclass
      end
    end

    render :update do |page|
      page.replace_html "classes_#{number}", :partial => "classes"
      page.visual_effect :toggle_blind, "classes_#{number}", :duration => 0.5
    end
  end

  def list_modules
    number = params[:number].to_i
    script, result, output = Bio::Shell.cache[:results].restore(number)
    @class = result.class
    @modules = result.class.included_modules - HIDE_MODULES

    render :update do |page|
      page.replace_html "modules_#{number}", :partial => "modules"
      page.visual_effect :toggle_blind, "modules_#{number}", :duration => 0.5
    end
  end

  def results
    if Bio::Shell.cache[:results].number > 0
      limit = params[:limit].to_i
      max_num = Bio::Shell.cache[:results].number
      min_num = [ max_num - limit + 1, 1 ].max
      min_num = 1 if limit == 0

      render :update do |page|
        # delete all existing results in the current DOM for clean up
        page.select(".evaluate").each do |element|
          page.remove element
        end

        # add selected results to the current DOM
        min_num.upto(max_num) do |@number|
          @script, @result, @output = Bio::Shell.cache[:results].restore(@number)
          if @script
            page.insert_html :after, "console", :partial => "result"
            page.replace_html "variables", :partial => "variables"
            page.hide "methods_#{@number}"
            page.hide "classes_#{@number}"
            page.hide "modules_#{@number}"
          end
        end
      end
    end
  end

  def commands
    @bioruby_commands = Bio::Shell.private_instance_methods.sort
  end

  def history
    @history = File.readlines(Bio::Shell.history_file)
  end

end

