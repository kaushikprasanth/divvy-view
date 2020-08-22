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
	el: $('#options'),
	events :
		'input input#params' : 'searchStations'
		'input input#eBike_only' : 'eBikeStations'
	collection:new System(),
	template: _.template('<div>
	<input id="params" type="text" autofocus value=<%=queryString%> >
	<input id="eBike_only" type="checkbox"> E-Bikes Only</input>'),

	initialize: ->
		this.render()
		this.collection.fetch()
		this.collection.on('update',this.collectionIntialized,this)

	render: () ->
		map = L.map('mapid').setView([41.8781,-87.6298], 13)
		window.map = map
		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
			attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
		}).addTo(map)
		this.$el.html(this.template({queryString:''}))
		this

	collectionIntialized:() ->
		listView = new ListView(this.collection.toJSON())
		layerGroup = L.layerGroup().addTo(window.map);
		window.markerLayer=layerGroup
		_.each(this.collection.toJSON(),(station) -> 
			marker = L.marker([station.lat,station.lon]).bindPopup(station.name)
			layerGroup.addLayer(marker);
		)
		overlay = {'Layer': layerGroup};
		L.control.layers(null, overlay).addTo(window.map);

	searchStations: (event)->
		arr = @collection.toJSON()
		layerGroup = window.markerLayer
		layerGroup.remove()
		layerGroup = L.layerGroup().addTo(window.map);
		window.markerLayer=layerGroup
		arr = (station for station in arr when station['name'].toLowerCase().indexOf(event.target.value.toLowerCase()) > -1)
		if $('#eBike_only')[0].checked
			arr = (station for station in arr when station['num_ebikes_available'] > 0)
		_.each(arr,(station) -> 
			marker = L.marker([station.lat,station.lon]).bindPopup(station.name)
			layerGroup.addLayer(marker);
		)
		listView = new ListView(arr)

	eBikeStations:()->
		layerGroup = window.markerLayer
		layerGroup.remove()
		layerGroup = L.layerGroup().addTo(window.map);
		arr = @collection.toJSON()
		window.markerLayer=layerGroup
		console.log $('#eBike_only')
		if $('#eBike_only')[0].checked
			arr = (station for station in arr when station['num_ebikes_available'] > 0)
		console.log arr.length
		_.each(arr,(station) -> 
			marker = L.marker([station.lat,station.lon]).bindPopup(station.name)
			layerGroup.addLayer(marker);
		)
		listView = new ListView(arr)
})
ListView = Backbone.View.extend({
	el: $('#home'),
	template: _.template('
<div class="grid-x" style="padding:20px">
<% _.each(stations,function (station){ %> 
<div class="small-3 cell">
 <div class="card" style="width: 300px;">
  <div class="card-divider">
    <span
		<% if (station.num_ebikes_available > 0) {%>
	style="font-weight:bold"
	<% } %>
	>
	<%=station.name %>
    <% if (station.num_ebikes_available > 0) {%>
    (E-Bike)
    <% } %>
	</span>
  </div>
  <div class="card-section">
  <% if (station.num_ebikes_available > 0) {%>
    <p style="color:green">E Bikes :<%=station.num_ebikes_available%></p>
	<% } %>
    <p>Bikes :<%=station.num_bikes_available%></p>
    <p>Docks :<%=station.num_docks_available%></p>

  </div>
</div>
</div>
<% }) %>
</div>'),
	initialize: (stations_arr)->
		this.render(stations_arr)
	render: (stations_arr) ->
		this.$el.html(this.template({stations:stations_arr}));

})
$( document ).ready(() -> 
	mainView = new MainView()
)
