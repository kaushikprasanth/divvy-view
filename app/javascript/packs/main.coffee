Station = Backbone.Model.extend({
	idAttribute: "station_id",
	defaults:{
		fav: false
	}
})
System = Backbone.Collection.extend({
	url: '/api/divvy_data',
	model:Station,
	comparator:(model) ->
		!model.get('fav')
	parse: (data) ->
		data.stations;
})
MainView = Backbone.View.extend({
	el: $('#options'),
	events :
		'input input#params' : 'searchStations'
		'input input#eBike_only' : 'eBikeStations'
	collection:new System(),
	template: _.template('<div class="grid-x grid-margin-x grid-padding-x">
  		<div class="cell small-8"><input id="params" type="text" placeholder="Search Stations" value=<%=queryString%> ></div>
  		<div class="cell small-4"><input id="eBike_only" type="checkbox"> E-Bikes Only</input></div>
		</div>'),

	initialize: ->
		self = this
		this.render()
		this.collection.fetch()
		this.collection.on('update',this.collectionIntialized,this)
		this.collection.on('sort',this.sorted,this)


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
			(error) -> console.log 'Location Access Denied',
			{enableHighAccuracy: true, timeout:15000} )
		window.map = map
		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
			attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
		}).addTo(map)
		this.$el.html(this.template({queryString:''}))
		this
	sorted :()->
		listView = new ListView(this.collection.toJSON(),this.addFavourite.bind(this))

	collectionIntialized:() ->
		self = this
		fav = if localStorage.getItem('divvy_favourite') then JSON.parse(localStorage.getItem('divvy_favourite')) else []
		_.each(fav, (id) ->
			self.collection.get(id).set({'fav':true}, {silent: true})
		)
		this.collection.sort('fav')

		if window.markerLayer?
			layerGroup = window.markerLayer
			layerGroup.remove()
			layerGroup = L.layerGroup().addTo(window.map);
			this.addMarkers(layerGroup,this.collection.toJSON())
			window.markerLayer=layerGroup
		else
			layerGroup = L.layerGroup().addTo(window.map);
			window.markerLayer=layerGroup
			this.addMarkers(layerGroup,this.collection.toJSON())
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
		this.addMarkers(layerGroup,arr)
		listView = new ListView(arr,this.addFavourite.bind(this))

	eBikeStations:()->
		layerGroup = window.markerLayer
		layerGroup.remove()
		layerGroup = L.layerGroup().addTo(window.map);
		arr = @collection.toJSON()
		window.markerLayer=layerGroup
		if $('#eBike_only')[0].checked
			arr = (station for station in arr when station['num_ebikes_available'] > 0)
		this.addMarkers(layerGroup,arr)
		listView = new ListView(arr)
	
	addMarkers:(layerGroup,stations)->
		LeafIcon = L.Icon.extend({
					options: 
						iconSize: [38, 38]
						iconAnchor: [22, 37]
						popupAnchor: [-3, -37]
				})
		electric = new LeafIcon({iconUrl: '/icons/icons8-electric.png'})
		available = new LeafIcon({iconUrl: '/icons/icons8-available.png'})
		empty = new LeafIcon({iconUrl: '/icons/icons8-empty.png'})
		_.each(stations,(station) ->
			Icon = empty
			if station.num_ebikes_available > 0
				Icon = electric
			else if station.num_bikes_available > 0
				Icon = available
			marker = L.marker([station.lat,station.lon], {icon: Icon}).bindPopup(station.name)
			layerGroup.addLayer(marker);
		)
		if stations.length > 0 
			window.map.setView([stations[0].lat,stations[0].lon], 13)
		
	
	addFavourite: (event) ->
		arr= if localStorage.getItem('divvy_favourite') then JSON.parse(localStorage.getItem('divvy_favourite')) else []
		if event.target.id not in arr
			arr.push event.target.id
			this.collection.get(event.target.id).set({'fav':true}, {silent: true})
			this.collection.sort('fav')
			window.localStorage.setItem('divvy_favourite',JSON.stringify(arr) );
	
})
ListView = Backbone.View.extend({
	el: $('#home'),
	template: _.template('
		<div class="grid-x grid-margin-x" style="padding:20px">
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
			<img id=<%=station.station_id %> class="favourite" style="height:24px;width:24px;cursor:pointer"
			<% if (station.fav) {%>
			src="/icons/icons8-bookmark.png"
			<% } else {%>
			src="/icons/icons8-bookmark-empty.png"
			<% } %>
			/>
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
		'click .favourite': 'addFavourite'
	initialize: (stations_arr,addFavourite)->
		this.render(stations_arr,addFavourite)
		this.addFavourite_p = addFavourite
	render: (stations_arr) ->
		this.$el.html(this.template({stations:stations_arr}));
	addFavourite:(event)->
		this.addFavourite_p(event)
	
})
$( document ).ready(() -> 
	mainView = new MainView()
)
# <img src="https://img.icons8.com/dusk/64/000000/bookmark-ribbon.png"/>
