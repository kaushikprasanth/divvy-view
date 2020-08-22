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
		navigator.geolocation.getCurrentPosition(
			(position) ->
				LeafIcon = L.Icon.extend({
					options: 
						iconSize: [38, 38]
						iconAnchor: [22, 37]
						popupAnchor: [-3, -37]
				})
				greenIcon = new LeafIcon({iconUrl: 'https://img.icons8.com/fluent/48/000000/map-pin.png'})
				L.marker([position.coords.latitude,position.coords.longitude], {icon: greenIcon}).addTo(map).bindPopup("You are Here")
				map.setView([position.coords.latitude,position.coords.longitude], 15)
			(error) -> alert 'Error occurred. Error code: ' + error.code,
			{enableHighAccuracy: true,  timeout:15000} )
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
		if $('#eBike_only')[0].checked
			arr = (station for station in arr when station['num_ebikes_available'] > 0)
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
<div class="small-6 cell">
 <div class="card" >
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
	<img id=<%=station.station_id %> class="favourite" style="height:24px;width:24px"
	src="https://img.icons8.com/wired/64/000000/bookmark-ribbon.png"/>
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
	events:
		'click .favourite':'addFavourite'
	initialize: (stations_arr)->
		this.render(stations_arr)
	render: (stations_arr) ->
		arr= if localStorage.getItem('divvy_favourite') then localStorage.getItem('divvy_favourite') else []
		this.$el.html(this.template({stations:stations_arr,favourites:arr}));
	addFavourite: (event) ->
		# arr= if localStorage.getItem('divvy_favourite') then localStorage.getItem('divvy_favourite') else []
		# arr.push(event.target.id)
		# window.localStorage.setItem('divvy_favourite',arr );

})
$( document ).ready(() -> 
	mainView = new MainView()
)
# <img src="https://img.icons8.com/dusk/64/000000/bookmark-ribbon.png"/>
