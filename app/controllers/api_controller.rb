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
            results['stations'].each do |station|
                station_name= results_info['stations'].select{ |h| h['station_id'] == station['station_id'] }
                # print(station_name)
                station['name'] = station_name[0]['name']
                station['lon'] = station_name[0]['lon']
                station['lat'] = station_name[0]['lat']

            end
       respond_with results
    end

    respond_to :json
    def sf
        url = 'https://account.baywheels.com/bikesharefe-gql'
        params = {operationName:'GetSystemSupply', variables:{}, query:"query GetSystemSupply {\n  supply {\n    stations {\n      stationId\n      stationName\n      location {\n        lat\n        lng\n        __typename\n      }\n      bikesAvailable\n      bikeDocksAvailable\n      ebikesAvailable\n      totalBikesAvailable\n      isValet\n      isOffline\n      isLightweight\n      displayMessages\n      siteId\n      ebikes {\n        batteryStatus {\n          distanceRemaining {\n            value\n            unit\n            __typename\n          }\n          percent\n          __typename\n        }\n        __typename\n      }\n      lastUpdatedMs\n      __typename\n    }\n    rideables {\n      location {\n        lat\n        lng\n        __typename\n      }\n      rideableType\n      batteryStatus {\n        distanceRemaining {\n          value\n          unit\n          __typename\n        }\n        percent\n        __typename\n      }\n      __typename\n    }\n    notices {\n      localizedTitle\n      localizedDescription\n      __typename\n    }\n    requestErrors {\n      localizedTitle\n      localizedDescription\n      __typename\n    }\n    __typename\n  }\n}\n"}.to_json
        
        begin
            r = RestClient::Request.execute(method: :post, url: url,payload: params,headers: { content_type: :json, accept: :json}, verify_ssl: false) 
            results =  JSON.parse(r.body.to_str)["data"]["supply"]['stations']
            results.each do |station|
                station['name'] = station['stationName']
                station['lon'] = station['location']['lng']
                station['lat'] = station['location']['lat']
                station['num_bikes_available'] = station['bikesAvailable']
                station['num_docks_available'] = station['bikeDocksAvailable']
                station['num_ebikes_available'] = station['ebikesAvailable']

        end
        rescue => e
           puts e.response
        end
       respond_with results
    end
end
