require 'rubygems'#comment out for deployment
require 'json'
require 'rio'
require 'fastercsv'


class Starspan
  
  #process, grab all variables, setup folders for sticking the data in, check on locations of rasters and vectors
    
  
  def initialize options = {}
    
    
    @raster = options[:raster]
    @vector = options[:vector]
    @stats = options[:stats]
    @data_folder = options[:data_folder]
    @starspan = options[:starspan]
   
    
    #raise error if invalid folders and rasters
    check_stuff 
    
    #set up all the places to put the files
    setup_folders    
    
  end
  
  
private
  def setup_folders
    dirs = ['csv', 'geojson']

    #first check the data folder exists if not add a new one
    
    puts @data_folder.to_s  
    
    unless File.exists? @data_folder
      Dir.mkdir("#{@data_folder}")
      dirs.each {|dir| Dir.mkdir("#{@data_folder}/#{dir}") } 
    end
    
        
  end
  
  def check_stuff
  
    #is raster/vector valid?
     raise "don't recognise raster" unless `starspan --raster #{@raster} --report`.lines.to_a[1].include? 'RASTER'
     raise "don't recognise vector" unless `starspan --vector #{@vector} --report`.lines.to_a[1].include? "VECTOR"    
    
  end
  
  def csvtohash csv_path
    #turn csv into a hash then json (will only ever be one header row and one data row- TODO: change for multiple rasters for now)
   
    multiout = []
    FasterCSV.foreach(csv_path, :headers => :first_row) do |row|
      output = {}
      row.each { |hed, val|
        output[hed] = val
      }
      
     multiout << output 
      
    end
    
    multiout
  end
  
  
public


  def run_starspan
    
    #create new file id for the process using current time in microseconds
    @fileid = Time.now.to_f.to_s.gsub!(".","")
  
    system  "#{@starspan} --vector #{@vector} --raster #{@raster} --stats #{@data_folder}/csv/#{@fileid}.csv #{@stats.join(',')}"
    
    #TODO: make the command running better - try open4
    starttime = Time.now
    until rio("#{@data_folder}/csv/#{@fileid}.csv").exist?() || (Time.now - starttime) > 20
      sleep 0.1
    end

    #read file here and return the value of the output as a hash
    if rio("#{@data_folder}/csv/#{@fileid}.csv").exist?()    
      #unpackage csv and return as json with the 
        out = csvtohash("#{@data_folder}/csv/#{@fileid}.csv")
    else
        out = "no_csv"
    end
  
  
  end
  
  
  
  
end