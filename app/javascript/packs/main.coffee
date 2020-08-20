Station = Backbone.Model.extend({
initialize: ->
	console.log('Here in Model Initialize')
defaults:{
	id:'',
	name:'',
}
})
MainView = Backbone.View.extend({
	el: $('#home'),
	template: _.template("<h1>Hi <%= name %></h1>"),
	initialize: ->
		this.render()
	render: () ->
		map = L.map('mapid').setView([51.505, -0.09], 13)
		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
			attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
		}).addTo(map)
		L.marker([51.5, -0.09]).addTo(map)
			.bindPopup('A pretty CSS3 popup.<br> Easily customizable.')
			.openPopup()
		this.$el.html(this.template({name:'Im Backbone js'}));
		this
})
$( document ).ready(() -> 
	mainView = new MainView()
)