// Global namespace: window.UniYouth.EventLocationPicker
(function () {
    'use strict';

    function debounce(fn, delayMs) {
        var timerId = null;
        return function () {
            var context = this;
            var args = arguments;
            if (timerId) window.clearTimeout(timerId);
            timerId = window.setTimeout(function () {
                timerId = null;
                fn.apply(context, args);
            }, delayMs);
        };
    }

    function toFixed6(value) {
        if (typeof value !== 'number' || Number.isNaN(value)) return '';
        return value.toFixed(6);
    }

    function parseNumber(value) {
        if (value === null || value === undefined) return null;
        var trimmed = String(value).trim();
        if (!trimmed) return null;
        var n = Number(trimmed);
        return Number.isFinite(n) ? n : null;
    }

    function parseAccuracy(value) {
        if (value === null || value === undefined) return null;
        var n = Number(value);
        return Number.isFinite(n) && n >= 0 ? n : null;
    }

    function delay(ms) {
        return new Promise(function (resolve) {
            window.setTimeout(resolve, ms);
        });
    }

    function formatAccuracy(accuracyMeters) {
        if (accuracyMeters === null || accuracyMeters === undefined) {
            return 'không xác định';
        }

        return accuracyMeters.toFixed(1) + 'm';
    }

    function averagePositionSamples(samples) {
        if (!Array.isArray(samples) || samples.length === 0) {
            return null;
        }

        var latSum = 0;
        var lngSum = 0;
        var accuracySum = 0;
        var accuracyCount = 0;

        for (var i = 0; i < samples.length; i++) {
            latSum += samples[i].lat;
            lngSum += samples[i].lng;

            if (samples[i].accuracy !== null) {
                accuracySum += samples[i].accuracy;
                accuracyCount += 1;
            }
        }

        return {
            lat: latSum / samples.length,
            lng: lngSum / samples.length,
            accuracy: accuracyCount > 0 ? accuracySum / accuracyCount : null
        };
    }

    async function captureBestPosition(geolocationOptions) {
        var options = geolocationOptions || {};
        var sampleCount = typeof options.sampleCount === 'number' && options.sampleCount > 0
            ? Math.trunc(options.sampleCount)
            : 2;
        var sampleDelayMs = typeof options.sampleDelayMs === 'number' && options.sampleDelayMs >= 0
            ? options.sampleDelayMs
            : 450;

        function getSinglePosition() {
            return new Promise(function (resolve, reject) {
                navigator.geolocation.getCurrentPosition(resolve, reject, {
                    enableHighAccuracy: options.enableHighAccuracy !== false,
                    timeout: typeof options.timeout === 'number' ? options.timeout : 8000,
                    maximumAge: typeof options.maximumAge === 'number' ? options.maximumAge : 5000
                });
            });
        }

        var acceptedSamples = [];

        for (var i = 0; i < sampleCount; i++) {
            var position = await getSinglePosition();
            var lat = position && position.coords ? position.coords.latitude : null;
            var lng = position && position.coords ? position.coords.longitude : null;
            var accuracy = parseAccuracy(position && position.coords ? position.coords.accuracy : null);

            if (typeof lat === 'number' && typeof lng === 'number') {
                acceptedSamples.push({
                    lat: lat,
                    lng: lng,
                    accuracy: accuracy
                });
            }

            if (i < sampleCount - 1) {
                await delay(sampleDelayMs);
            }
        }

        if (acceptedSamples.length === 0) {
            throw new Error('NO_POSITION');
        }

        return averagePositionSamples(acceptedSamples) || acceptedSamples[0];
    }

    async function fetchJson(url) {
        var resp = await fetch(url, {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            }
        });

        if (!resp.ok) {
            throw new Error('HTTP ' + resp.status);
        }

        return await resp.json();
    }

    function init(options) {
        if (!options) throw new Error('Missing options');

        var locationNameInput = document.getElementById(options.locationNameInputId);
        var latitudeInput = document.getElementById(options.latitudeInputId);
        var longitudeInput = document.getElementById(options.longitudeInputId);
        var mapContainer = document.getElementById(options.mapContainerId);

        if (!locationNameInput || !latitudeInput || !longitudeInput || !mapContainer) {
            return null;
        }

        var coordsEl = options.coordsElementId ? document.getElementById(options.coordsElementId) : null;
        var statusEl = options.statusElementId ? document.getElementById(options.statusElementId) : null;
        var useMyLocationBtn = options.useMyLocationButtonId
            ? document.getElementById(options.useMyLocationButtonId)
            : null;

        var defaultLat = typeof options.defaultLat === 'number' ? options.defaultLat : 10.7765;
        var defaultLng = typeof options.defaultLng === 'number' ? options.defaultLng : 106.6958;
        var defaultZoom = typeof options.defaultZoom === 'number' ? options.defaultZoom : 13;

        var suppressLocationHandler = false;
        var lastGeocodeQuery = '';
        var provider = null;

        function setStatus(text) {
            if (!statusEl) return;
            statusEl.textContent = text || '';
        }

        function setCoordsText(lat, lng, accuracyMeters) {
            if (!coordsEl) return;
            if (lat === null || lng === null) {
                coordsEl.textContent = 'Chưa chọn vị trí';
                return;
            }

            var accuracyText = accuracyMeters === undefined
                ? ''
                : ' • Sai số: ' + formatAccuracy(accuracyMeters);
            coordsEl.textContent = 'Tọa độ: ' + toFixed6(lat) + ', ' + toFixed6(lng) + accuracyText;
        }

        function createNoopProvider(message) {
            setStatus(message || 'Map service chưa được cấu hình.');
            setCoordsText(parseNumber(latitudeInput.value), parseNumber(longitudeInput.value), null);
            return {
                forwardGeocode: function () { },
                reverseGeocode: function () { },
                setLatLng: function () { },
                refresh: function () { }
            };
        }

        function initGoogleProvider() {
            var geocoder = new google.maps.Geocoder();
            var map = new google.maps.Map(mapContainer, {
                center: { lat: defaultLat, lng: defaultLng },
                zoom: defaultZoom,
                mapTypeControl: false,
                streetViewControl: false,
                fullscreenControl: true
            });
            var marker = null;

            function geocodeAsync(request) {
                return new Promise(function (resolve, reject) {
                    geocoder.geocode(request, function (results, status) {
                        if (status === 'OK' || status === google.maps.GeocoderStatus.OK) {
                            resolve(results || []);
                            return;
                        }

                        reject(new Error(String(status)));
                    });
                });
            }

            function setLatLng(lat, lng, moveMap, moveMarker, accuracyMeters) {
                latitudeInput.value = lat === null ? '' : toFixed6(lat);
                longitudeInput.value = lng === null ? '' : toFixed6(lng);
                setCoordsText(lat, lng, accuracyMeters);

                if (lat === null || lng === null) {
                    if (marker) {
                        marker.setMap(null);
                        marker = null;
                    }
                    return;
                }

                var position = { lat: lat, lng: lng };

                if (!marker) {
                    marker = new google.maps.Marker({
                        position: position,
                        map: map,
                        draggable: true
                    });

                    marker.addListener('dragend', function (e) {
                        if (!e.latLng) return;
                        var draggedLat = e.latLng.lat();
                        var draggedLng = e.latLng.lng();
                        setLatLng(draggedLat, draggedLng, false, false);
                        reverseGeocode(draggedLat, draggedLng);
                    });
                } else if (moveMarker) {
                    marker.setPosition(position);
                }

                if (moveMap) {
                    map.setCenter(position);
                    if (map.getZoom() < 15) {
                        map.setZoom(15);
                    }
                }
            }

            async function reverseGeocode(lat, lng) {
                try {
                    setStatus('Đang lấy tên địa điểm...');
                    var results = await geocodeAsync({
                        location: { lat: lat, lng: lng }
                    });

                    if (results.length > 0) {
                        suppressLocationHandler = true;
                        locationNameInput.value = results[0].formatted_address || '';
                        suppressLocationHandler = false;
                    }

                    setStatus('');
                } catch (e) {
                    setStatus('Không lấy được tên địa điểm.');
                }
            }

            async function forwardGeocode(query) {
                var trimmed = (query || '').trim();
                if (trimmed.length < 3) return;
                if (trimmed === lastGeocodeQuery) return;
                lastGeocodeQuery = trimmed;

                try {
                    setStatus('Đang tìm vị trí...');
                    var results = await geocodeAsync({ address: trimmed });
                    if (results.length > 0) {
                        var location = results[0].geometry && results[0].geometry.location;
                        if (location) {
                            setLatLng(location.lat(), location.lng(), true, true);
                            setStatus('');
                            return;
                        }
                    }

                    setStatus('Không tìm thấy vị trí phù hợp.');
                } catch (e) {
                    setStatus('Không thể tìm vị trí (lỗi mạng).');
                }
            }

            function refresh() {
                window.setTimeout(function () {
                    google.maps.event.trigger(map, 'resize');
                    if (marker) {
                        var markerPosition = marker.getPosition();
                        if (markerPosition) {
                            map.setCenter(markerPosition);
                        }
                    }
                }, 50);
            }

            var initialLat = parseNumber(latitudeInput.value);
            var initialLng = parseNumber(longitudeInput.value);
            if (initialLat !== null && initialLng !== null) {
                map.setCenter({ lat: initialLat, lng: initialLng });
                map.setZoom(16);
                setLatLng(initialLat, initialLng, false, true);
            } else {
                map.setCenter({ lat: defaultLat, lng: defaultLng });
                map.setZoom(defaultZoom);
                setCoordsText(null, null, null);
            }

            map.addListener('click', function (e) {
                if (!e.latLng) return;
                var lat = e.latLng.lat();
                var lng = e.latLng.lng();
                setLatLng(lat, lng, false, true);
                reverseGeocode(lat, lng);
            });

            return {
                forwardGeocode: forwardGeocode,
                reverseGeocode: reverseGeocode,
                setLatLng: setLatLng,
                refresh: refresh
            };
        }

        function initLeafletProvider() {
            var map = L.map(mapContainer, {
                zoomControl: true,
                attributionControl: true
            });
            var marker = null;

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap contributors'
            }).addTo(map);

            function setLatLng(lat, lng, moveMap, moveMarker, accuracyMeters) {
                latitudeInput.value = lat === null ? '' : toFixed6(lat);
                longitudeInput.value = lng === null ? '' : toFixed6(lng);
                setCoordsText(lat, lng, accuracyMeters);

                if (lat === null || lng === null) {
                    if (marker) {
                        map.removeLayer(marker);
                        marker = null;
                    }
                    return;
                }

                var latLng = L.latLng(lat, lng);

                if (!marker) {
                    marker = L.marker(latLng, { draggable: true }).addTo(map);
                    marker.on('dragend', function () {
                        var p = marker.getLatLng();
                        setLatLng(p.lat, p.lng, false, false);
                        reverseGeocode(p.lat, p.lng);
                    });
                } else if (moveMarker) {
                    marker.setLatLng(latLng);
                }

                if (moveMap) {
                    map.setView(latLng, Math.max(map.getZoom(), 15));
                }
            }

            async function reverseGeocode(lat, lng) {
                try {
                    setStatus('Đang lấy tên địa điểm...');
                    var url =
                        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=' +
                        encodeURIComponent(lat) +
                        '&lon=' +
                        encodeURIComponent(lng);

                    var data = await fetchJson(url);
                    if (data && data.display_name) {
                        suppressLocationHandler = true;
                        locationNameInput.value = data.display_name;
                        suppressLocationHandler = false;
                    }
                    setStatus('');
                } catch (e) {
                    setStatus('Không lấy được tên địa điểm.');
                }
            }

            async function forwardGeocode(query) {
                var trimmed = (query || '').trim();
                if (trimmed.length < 3) return;
                if (trimmed === lastGeocodeQuery) return;
                lastGeocodeQuery = trimmed;

                try {
                    setStatus('Đang tìm vị trí...');
                    var url =
                        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=' +
                        encodeURIComponent(trimmed) +
                        '&limit=1';

                    var results = await fetchJson(url);
                    if (Array.isArray(results) && results.length > 0) {
                        var result = results[0];
                        var lat = parseNumber(result.lat);
                        var lng = parseNumber(result.lon);
                        if (lat !== null && lng !== null) {
                            setLatLng(lat, lng, true, true);
                            setStatus('');
                            return;
                        }
                    }

                    setStatus('Không tìm thấy vị trí phù hợp.');
                } catch (e) {
                    setStatus('Không thể tìm vị trí (lỗi mạng).');
                }
            }

            function refresh() {
                try {
                    window.setTimeout(function () {
                        map.invalidateSize();
                    }, 50);
                } catch (e) {
                    // ignore
                }
            }

            var initialLat = parseNumber(latitudeInput.value);
            var initialLng = parseNumber(longitudeInput.value);
            if (initialLat !== null && initialLng !== null) {
                map.setView([initialLat, initialLng], 16);
                setLatLng(initialLat, initialLng, false, true);
            } else {
                map.setView([defaultLat, defaultLng], defaultZoom);
                setCoordsText(null, null, null);
            }

            map.on('click', function (e) {
                setLatLng(e.latlng.lat, e.latlng.lng, false, true);
                reverseGeocode(e.latlng.lat, e.latlng.lng);
            });

            return {
                forwardGeocode: forwardGeocode,
                reverseGeocode: reverseGeocode,
                setLatLng: setLatLng,
                refresh: refresh
            };
        }

        function isMapContainerVisible() {
            return !!(mapContainer.offsetParent || mapContainer.getClientRects().length);
        }

        function ensureProvider() {
            if (provider) {
                return provider;
            }

            provider = window.google && window.google.maps
                ? initGoogleProvider()
                : (window.L ? initLeafletProvider() : createNoopProvider('Map service chưa được cấu hình.'));

            return provider;
        }

        if (isMapContainerVisible()) {
            ensureProvider();
        } else {
            setCoordsText(parseNumber(latitudeInput.value), parseNumber(longitudeInput.value), null);
        }

        function setButtonBusy(isBusy) {
            if (!useMyLocationBtn) return;
            useMyLocationBtn.disabled = !!isBusy;
            useMyLocationBtn.setAttribute('aria-disabled', String(!!isBusy));
        }

        function enableGeolocation() {
            if (!useMyLocationBtn) return;

            useMyLocationBtn.addEventListener('click', function (e) {
                e.preventDefault();

                if (!navigator.geolocation) {
                    setStatus('Trình duyệt không hỗ trợ GPS.');
                    return;
                }

                setButtonBusy(true);
                setStatus('Đang lấy vị trí hiện tại...');

                captureBestPosition({
                    enableHighAccuracy: true,
                    timeout: typeof options.gpsTimeoutMs === 'number' ? options.gpsTimeoutMs : 8000,
                    maximumAge: typeof options.gpsMaximumAgeMs === 'number' ? options.gpsMaximumAgeMs : 5000,
                    sampleCount: typeof options.gpsSampleCount === 'number' ? options.gpsSampleCount : 2,
                    sampleDelayMs: typeof options.gpsSampleDelayMs === 'number' ? options.gpsSampleDelayMs : 450
                }).then(function (sample) {
                    var maxGpsAccuracyMeters = typeof options.maxGpsAccuracyMeters === 'number'
                        ? options.maxGpsAccuracyMeters
                        : 25;
                    var accuracyWarning = null;

                    if (sample.accuracy !== null && sample.accuracy > maxGpsAccuracyMeters) {
                        accuracyWarning =
                            'Đã lấy vị trí hiện tại nhưng GPS chưa ổn định (sai số ' +
                            formatAccuracy(sample.accuracy) +
                            '). Nên kiểm tra lại trên bản đồ trước khi lưu.';
                    }

                    if (typeof sample.lat === 'number' && typeof sample.lng === 'number') {
                        var activeProvider = ensureProvider();
                        activeProvider.setLatLng(sample.lat, sample.lng, true, true, sample.accuracy);
                        activeProvider.reverseGeocode(sample.lat, sample.lng);
                        setStatus(
                            accuracyWarning ||
                            ('Đã lấy vị trí hiện tại. Sai số ước tính: ' +
                                formatAccuracy(sample.accuracy))
                        );
                    } else {
                        setStatus('Không lấy được tọa độ.');
                    }

                    setButtonBusy(false);
                }).catch(function (err) {
                    var message = 'Không thể lấy GPS.';
                    if (err && err.code === 1) message = 'Bạn đã từ chối quyền GPS.';
                    if (err && err.code === 2) message = 'GPS không khả dụng.';
                    if (err && err.code === 3) message = 'Lấy GPS bị timeout.';
                    setStatus(message);
                    setButtonBusy(false);
                });
            });
        }

        enableGeolocation();

        var debouncedForward = debounce(function () {
            if (suppressLocationHandler) return;
            ensureProvider().forwardGeocode(locationNameInput.value);
        }, typeof options.forwardDebounceMs === 'number' ? options.forwardDebounceMs : 800);

        locationNameInput.addEventListener('input', debouncedForward);
        locationNameInput.addEventListener('blur', function () {
            if (suppressLocationHandler) return;
            ensureProvider().forwardGeocode(locationNameInput.value);
        });

        function setLocation(payload) {
            payload = payload || {};
            var name = payload.name === null || payload.name === undefined ? '' : String(payload.name);
            var lat = typeof payload.lat === 'number' && Number.isFinite(payload.lat) ? payload.lat : null;
            var lng = typeof payload.lng === 'number' && Number.isFinite(payload.lng) ? payload.lng : null;

            suppressLocationHandler = true;
            locationNameInput.value = name;
            suppressLocationHandler = false;

            var activeProvider = ensureProvider();
            activeProvider.setLatLng(lat, lng, true, true);

            if (lat !== null && lng !== null && payload.skipReverseGeocode !== true) {
                activeProvider.reverseGeocode(lat, lng);
            } else {
                setStatus('');
            }
        }

        return {
            setLocation: setLocation,
            refresh: function () {
                ensureProvider().refresh();
            }
        };
    }

    window.UniYouth = window.UniYouth || {};
    window.UniYouth.EventLocationPicker = {
        init: init
    };
})();
