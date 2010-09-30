#require 'rubygems'#comment out for deployment
#require 'sinatra'#comment out for deployment
require 'rio'
require 'starspan'

#return summary of % water fallen with PAs
post '/es/freshwater' do
  content_type :json
  
  #if params[:geomtype] == "ESRI Shapefile"
  json = raster_summary(params[:shp][:tempfile].path, "data/raster/freshwater/gl_pc_wc_fin").to_json
  params[:callback] ? "#{params[:callback]} (#{json})" : json
  
end

#return kba coverage (user will need to divide sum/pixel num)
post '/es/kba' do
  content_type :json
  
  #if params[:geomtype] == "ESRI Shapefile"
  json = raster_summary(params[:shp][:tempfile].path, "data/raster/kba/kba_ras/kba_1").to_json
  params[:callback] ? "#{params[:callback]} (#{json})" : json
  
 
end

#return carbon in tonnes
post '/es/carbon' do
  content_type :json
  
  #if params[:geomtype] == "ESRI Shapefile"
  json = raster_summary(params[:shp][:tempfile].path, "data/raster/carbon2010/carbon_1").to_json
  params[:callback] ? "#{params[:callback]} (#{json})" : json
  
 
end


#doing all the work by creating the folders hang off to the starspan class and returning the hash array
def raster_summary geom_path, raster
  
  
  #if params[:geomtype] == "ESRI Shapefile"
  
  
  #create folder to hold shp
  folder = "data/shp/#{Time.now.to_f.to_s.gsub!(".","")}"
  Dir.mkdir(folder)
 
  #unzip file
  system  "unzip #{geom_path} -d #{folder}"
    
  shp_path = ""
  #get path of shp
  rio(folder).all.files('*.shp') { |f| shp_path = f.to_s }

  #setup params for starspan
  options = {:raster => raster, 
              :vector => shp_path, 
              :stats=>["sum"], 
              :data_folder => "data3", 
              :starspan => "starspan"}

  #TODO: need a better way of waiting for the commands to be finished before carrying on....
  starttime = Time.now
  until rio("#{File.basename(shp_path, ".shp")}.shx").exist?() || (Time.now - starttime) > 20
    sleep 0.1
  end


  begin
    summary = Starspan.new(options)
    puts summary.to_s
    out = summary.run_starspan
    
  rescue Exception => e
    
  end
end


