// Helper for LocationPresets Create/Edit pages: fill Latitude/Longitude (and optionally Address) using browser GPS
(function () {
    'use strict';

    function toFixed6(value) {
        if (typeof value !== 'number' || Number.isNaN(value)) return '';
        return value.toFixed(6);
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

    async function captureBestPosition(options) {
        var geolocationOptions = options || {};
        var sampleCount = typeof geolocationOptions.sampleCount === 'number' && geolocationOptions.sampleCount > 0
            ? Math.trunc(geolocationOptions.sampleCount)
            : 2;
        var sampleDelayMs = typeof geolocationOptions.sampleDelayMs === 'number' && geolocationOptions.sampleDelayMs >= 0
            ? geolocationOptions.sampleDelayMs
            : 450;

        function getSinglePosition() {
            return new Promise(function (resolve, reject) {
                navigator.geolocation.getCurrentPosition(resolve, reject, {
                    enableHighAccuracy: geolocationOptions.enableHighAccuracy !== false,
                    timeout: typeof geolocationOptions.timeout === 'number' ? geolocationOptions.timeout : 8000,
                    maximumAge: typeof geolocationOptions.maximumAge === 'number' ? geolocationOptions.maximumAge : 5000
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
            headers: { 'Accept': 'application/json' }
        });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        return await resp.json();
    }

    async function reverseGeocodeWithGoogle(lat, lng) {
        return await new Promise(function (resolve, reject) {
            var geocoder = new google.maps.Geocoder();
            geocoder.geocode(
                { location: { lat: lat, lng: lng } },
                function (results, status) {
                    if (status === 'OK' || status === google.maps.GeocoderStatus.OK) {
                        if (Array.isArray(results) && results.length > 0) {
                            resolve(results[0].formatted_address || null);
                            return;
                        }

                        resolve(null);
                        return;
                    }

                    reject(new Error(String(status)));
                });
        });
    }

    async function reverseGeocodeWithNominatim(lat, lng) {
        var url =
            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=' +
            encodeURIComponent(String(lat)) +
            '&lon=' +
            encodeURIComponent(String(lng));
        var result = await fetchJson(url);
        return result && result.display_name ? String(result.display_name) : null;
    }

    async function reverseGeocode(lat, lng) {
        if (window.google && window.google.maps) {
            return await reverseGeocodeWithGoogle(lat, lng);
        }

        return await reverseGeocodeWithNominatim(lat, lng);
    }

    function bind(options) {
        options = options || {};
        var button = document.getElementById(options.buttonId);
        var latInput = document.getElementById(options.latitudeInputId);
        var lngInput = document.getElementById(options.longitudeInputId);
        var addressInput = options.addressInputId ? document.getElementById(options.addressInputId) : null;
        var statusEl = options.statusElementId ? document.getElementById(options.statusElementId) : null;

        if (!button || !latInput || !lngInput) return;

        function setStatus(text) {
            if (!statusEl) return;
            statusEl.textContent = text || '';
        }

        function setBusy(isBusy) {
            button.disabled = !!isBusy;
            button.setAttribute('aria-disabled', String(!!isBusy));
        }

        button.addEventListener('click', function (e) {
            e.preventDefault();

            if (!navigator.geolocation) {
                setStatus('Trình duyệt không hỗ trợ GPS.');
                return;
            }

            setBusy(true);
            setStatus('Đang lấy vị trí hiện tại...');

            captureBestPosition({
                enableHighAccuracy: true,
                timeout: 8000,
                maximumAge: 5000,
                sampleCount: 2,
                sampleDelayMs: 450
            }).then(async function (pos) {
                try {
                    var lat = pos ? pos.lat : null;
                    var lng = pos ? pos.lng : null;
                    var accuracy = pos ? pos.accuracy : null;
                    var maxGpsAccuracyMeters = 25;
                    var accuracyWarning = null;

                    if (accuracy !== null && accuracy > maxGpsAccuracyMeters) {
                        accuracyWarning =
                            'Đã lấy vị trí hiện tại nhưng GPS chưa ổn định (sai số ' +
                            formatAccuracy(accuracy) +
                            '). Nên kiểm tra lại trên bản đồ trước khi lưu.';
                    }

                    if (typeof lat === 'number' && typeof lng === 'number') {
                        latInput.value = toFixed6(lat);
                        lngInput.value = toFixed6(lng);

                        if (addressInput) {
                            try {
                                setStatus('Đang lấy địa chỉ...');
                                var address = await reverseGeocode(lat, lng);
                                if (address) {
                                    addressInput.value = address;
                                }
                            } catch (err) {
                                // ignore reverse geocode error
                            }
                        }

                        setStatus(
                            accuracyWarning ||
                            ('Đã lấy vị trí hiện tại. Sai số ước tính: ' +
                                formatAccuracy(accuracy))
                        );
                    } else {
                        setStatus('Không lấy được tọa độ.');
                    }
                } finally {
                    setBusy(false);
                }
            }).catch(function (err) {
                var message = 'Không thể lấy GPS.';
                if (err && err.code === 1) message = 'Bạn đã từ chối quyền GPS.';
                if (err && err.code === 2) message = 'GPS không khả dụng.';
                if (err && err.code === 3) message = 'Lấy GPS bị timeout.';
                setStatus(message);
                setBusy(false);
            });
        });
    }

    window.UniYouth = window.UniYouth || {};
    window.UniYouth.LocationPresetsGps = {
        bind: bind
    };
})();
