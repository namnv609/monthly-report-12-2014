$ ->
    map = null
    infoWindow = null
    placesSvc = null
    globalLatLng = null
    placeIconDir = 'images/'
    directionsDisplay = null
    directionsSvc = new google.maps.DirectionsService()

    
    initLatLng = (position) ->
        lat = position.coords.latitude
        lng = position.coords.longitude

        $ "#latLngContainer"
            .text "#{lat}-#{lng}"

        initMap lat, lng, '', 0

    initMap = (lat, lng, kw, radius) ->
        directionsDisplay = new google.maps.DirectionsRenderer
            suppressMarkers: true
        latLng = new google.maps.LatLng lat, lng
        mapZoom = 13
        globalLatLng = latLng if $ "#latLngContainer"
            .text()

        switch radius
            when "500"
                mapZoom = 15
            when "1000"
                mapZoom = 14
            when "2000", "3000"
                mapZoom = 13
            when "4000", "5000", "6000"
                mapZoom = 12
            when "7000", "8000", "9000", "10000"
                mapZoom = 11

        mapOptions =
            zoom: mapZoom
            center: latLng
            mapTypeId: google.maps.MapTypeId.ROADMAP

        map = new google.maps.Map document.getElementById("map-canvas"), mapOptions
        directionsDisplay.setMap map

        currentMarker = new google.maps.Marker
            map: map
            position: latLng
            animation: google.maps.Animation.DROP
            icon: "#{placeIconDir}curr_loc.png"
            draggable: true

        placesRequest = 
            location: latLng
            radius: radius,
            keyword: kw

        placesSvc = new google.maps.places.PlacesService map
        infoWindow = new google.maps.InfoWindow()

        placesSvc.nearbySearch placesRequest, getPlaces

        google.maps.event.addListener currentMarker, 'dragend', (e) ->
            lat = e.latLng.lat()
            lng = e.latLng.lng()
            globalLatLng = new google.maps.LatLng lat, lng
            $ "#latLngContainer"
                .text "#{lat}-#{lng}"

    getPlaces = (results, status) ->
        pS = placesSvc
        pPhone = 'N/A'
        pWeb = 'N/A'
        pImage = "#{placeIconDir}default_place_img.jpg"
        pMoreInfo = ''
        $ "#resultList"
            .html ''

        drawRadius = parseInt $("#radius").val()
        drawCircle = new google.maps.Circle
            map: map
            center: globalLatLng
            radius: drawRadius
            strokeColor: '#FF0000'
            strokeOpacity: 0.8
            strokeWeight: 1
            fillColor: '#FF0000'
            fillOpacity: 0.35

        if status is google.maps.places.PlacesServiceStatus.OK
            i = 0
            while i < results.length
                placeMarker results[i]

                detailReq = 
                    reference: results[i].reference

                pS.getDetails detailReq, (details, s) ->
                    pPhone = details.formatted_phone_number if details.formatted_phone_number
                    pWeb = "<a href='#{details.website}' target='_blank'>#{details.name}</a>" if details.website
                    pImage = details.photos[0].getUrl 'maxWidth': 88, 'maxHeight': 88 if details.photos
                    pMoreInfo = "<a href='#{details.url}' target='_blank'>More info</a>" if details.url
                    return
                i++
        else
            alert 'Cannot find places'

        google.maps.event.addListener map, 'click', ->
            infoWindow.close()
            return
        return

    placeMarker = (places) ->
        placeLoc = places.geometry.location
        detailReq = reference: places.reference
        pPhone = 'N/A'
        pWeb = 'N/A'
        pImage = "#{placeIconDir}default_place_img"
        pMoreInfo = ''

        marker = new google.maps.Marker
            map: map
            position: placeLoc
            animation: google.maps.Animation.DROP

        google.maps.event.addListener marker, 'click', (e) ->
            req = 
                origin: globalLatLng,
                destination: e.latLng
                travelMode: google.maps.DirectionsTravelMode.DRIVING
            if $ "#direction"
                .is ":checked"
                    directionsSvc.route req, (r, s) ->
                        if s is google.maps.DirectionsStatus.OK
                            directionsDisplay.setDirections r
                        else
                            alert 'err'
                        return
            return

        google.maps.event.addListener marker, 'click', ->
            placesSvc.getDetails detailReq, (details, status) ->
                pPhone = details.formatted_phone_number if details.formatted_phone_number
                pWeb = "<a href='#{details.website}' target='_blank'>#{details.name}</a>" if details.website
                pImage = details.photos[0].getUrl 'maxWidth': 88, 'maxHeight': 88 if details.photos
                pMoreInfo = "<a href='#{details.url}' target='_blank'>More info</a>" if details.url
            
                infoWindow.setContent "<img src='#{pImage}' style='margin-right: 10px; float: left; border: 1px solid #CCC;' alt='http://namnv609.cf' /><b>#{details.name}</b> - #{pMoreInfo}<br /><br />- Địa chỉ: #{details.formatted_address}<br />- Điện thoại: #{pPhone}<br />- Website: #{pWeb}"
                return
            infoWindow.open map, this
            return
        return

    getSearchParams = ->
        $latLngContainer = $ "#latLngContainer"
        lat = $latLngContainer.text().split('-')[0]
        lng = $latLngContainer.text().split('-')[1]
        kw = $ "#keyword"
            .val().trim()
        radius = $ "#radius"
            .val()

        if kw isnt null and kw isnt ''
            initMap lat, lng, kw, radius
        else if lat is '' or !lat? or lat is `undefined` or lng is '' or !lng? or lng is 'undefined'
            alert 'Cannot get current location. Plz try again later'
        else
            $ "#keyword"
                .focus()
        return

    $ "#keyword"
        .on "keypress", (e) ->
            getSearchParams() if e.keyCode is 13


    $ "#radius"
        .on "change", ->
            getSearchParams()

    $ "#search"
        .on "click", ->
            getSearchParams()

    if navigator.geolocation
        navigator.geolocation.getCurrentPosition initLatLng
    else
        alert 'Your browser does not support Geolocation. Please upgrade your browser to latest version.'
