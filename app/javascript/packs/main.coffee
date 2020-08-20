view = '''
       <input id="params" type="text" value=<%=@queryString%> />
       <div class="grid-x" style="padding:20px">
       <% console.log @stations.models[0] %>
       <% if @stations.models[0]? : %>
       <% for station in @stations.models[0].attributes.stations: %> 
       <div class="small-3 cell">
        <div class="card" style="width: 300px;">
         <div class="card-divider">
           <%=station.station_id %>
           <%=station.name %>
           <% if station.num_ebikes_available > 0 : %>
           (E-Bike)
           <% end %>
         </div>
         <div class="card-section">
           <p><%=station.num_ebikes_available%></p>
         </div>
       </div>
       </div>
       <% end %>
       <% end %>
       </div>
       '''

Station = Backbone.Model.extend({
defaults:{
	id:'',
	name:'',
}
})
System = Backbone.Collection.extend({
	url: '/api/divvy_data',
	parse: (data) ->
		data.stations;

})
MainView = Backbone.View.extend({
	el: $('#home'),
	events :
		'change input#params' : 'searchStations'

	collection:new System(),
	template: _.template('<input id="params" type="text" />
<div class="grid-x" style="padding:20px">
<% _.each(stations,function (station){ %> 
<div class="small-3 cell">
 <div class="card" style="width: 300px;">
  <div class="card-divider">
    <%=station.station_id %>
    <%=station.name %>
    <% if (station.num_ebikes_available > 0) {%>
    (E-Bike)
    <% } %>
  </div>
  <div class="card-section">
    <p><%=station.num_ebikes_available%></p>
  </div>
</div>
</div>
<% }) %>
</div>'),
	initialize: ->
		this.render()
		this.collection.fetch()
		this.collection.on('update',this.collectionIntialized,this)

	render: () ->
		map = L.map('mapid').setView([41.8781,-87.6298], 13)
		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
			attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
		}).addTo(map)
		this
	collectionIntialized:() ->
		console.log('collectionIntialized Called')
		this.$el.html(this.template({stations:this.collection.toJSON()}));
		# _.each(this.collection.toJSON(),(station) -> 
		# 	L.marker([station.lat,station.lon]).addTo(map)
		# 	.bindPopup(station.name)
		# )
	searchStations: (event)->
		console.log 'Search Called',event,event.target.value
		(station for station in @collection.models[0].attributes.stations if station['name'].toLowerCase().indexOf(event.target.value) > -1)

		this.$el.html(this.template({stations:this.collection.toJSON()}));

})
$( document ).ready(() -> 
	mainView = new MainView()
	# system = new System()
	# system.fetch()
	# console.log(system)
)
