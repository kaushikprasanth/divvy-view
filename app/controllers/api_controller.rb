require 'rest-client'
require 'json'
class ApiController < ApplicationController
    respond_to :json
    def index
       
        station_info = RestClient::Request.new(
            :method => :get,
            :url => 'https://gbfs.divvybikes.com/gbfs/en/station_information.json'
            ).execute
            results_info = JSON.parse(station_info.to_str)['data']
        station_status = RestClient::Request.new(
                    :method => :get,
                    :url => 'https://gbfs.divvybikes.com/gbfs/en/station_status.json'
                    ).execute
            results = JSON.parse(station_status.to_str)['data']
            results["stations"].each do |station|
                station_name= results_info['stations'].select{ |h| h['station_id'] == station['station_id'] }
                # print(station_name)
                station['name'] = station_name[0]['name']
                station['lon'] = station_name[0]['lon']
                station['lat'] = station_name[0]['lat']

            end
       respond_with results
    end
end
