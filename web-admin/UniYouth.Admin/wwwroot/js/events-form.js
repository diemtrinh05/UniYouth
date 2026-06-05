(function () {
    'use strict';

    function initDatePickers() {
        if (typeof window.flatpickr !== 'function') return;

        document.querySelectorAll('.js-ampm-datetime').forEach(function (input) {
            var picker = window.flatpickr(input, {
                enableTime: true,
                time_24hr: false,
                dateFormat: 'Y-m-d\\TH:i',
                altInput: true,
                altInputClass: 'form-control',
                altFormat: 'd/m/Y h:i K',
                allowInput: true
            });

            if (picker.altInput) {
                var labelText = '';
                if (input.id && window.CSS && typeof window.CSS.escape === 'function') {
                    var label = document.querySelector('label[for="' + window.CSS.escape(input.id) + '"]');
                    labelText = label ? label.textContent.trim().replace(/\s+/g, ' ') : '';
                }

                var accessibleName = input.getAttribute('aria-label') || labelText;
                if (accessibleName) {
                    picker.altInput.setAttribute('aria-label', accessibleName);
                }
            }
        });
    }

    function normalizeRadiusValue(value) {
        var text = String(value ?? '').trim();
        return text === '' ? null : text;
    }

    function initLocationPresetSync(picker, locationFields) {
        var allowRadiusInput = document.getElementById('AllowRadius');
        var lastAutoFilledRadius = allowRadiusInput ? normalizeRadiusValue(allowRadiusInput.value) : null;
        var allowRadiusManuallyEdited = false;

        if (allowRadiusInput) {
            allowRadiusInput.addEventListener('input', function () {
                allowRadiusManuallyEdited = normalizeRadiusValue(allowRadiusInput.value) !== lastAutoFilledRadius;
            });
        }

        var select = document.getElementById('locationPresetSelect');
        if (!select || !picker || typeof picker.setLocation !== 'function') return;

        select.addEventListener('change', function () {
            var opt = select.options[select.selectedIndex];
            if (!opt || !opt.value) return;

            var name = opt.getAttribute('data-name') || '';
            var lat = Number(opt.getAttribute('data-lat'));
            var lng = Number(opt.getAttribute('data-lng'));
            var radiusStr = opt.getAttribute('data-radius');
            var radius = radiusStr === null || radiusStr === '' ? null : Number(radiusStr);

            if (Number.isFinite(lat) && Number.isFinite(lng)) {
                picker.setLocation({ name: name, lat: lat, lng: lng, skipReverseGeocode: true });
            } else if (name) {
                picker.setLocation({ name: name, lat: null, lng: null, skipReverseGeocode: false });
            }

            if (radius !== null && Number.isFinite(radius) && allowRadiusInput) {
                var nextRadius = String(Math.trunc(radius));
                var currentRadius = normalizeRadiusValue(allowRadiusInput.value);
                var shouldAutoFill = !allowRadiusManuallyEdited
                    || currentRadius === null
                    || currentRadius === lastAutoFilledRadius;

                if (shouldAutoFill) {
                    allowRadiusInput.value = nextRadius;
                    lastAutoFilledRadius = nextRadius;
                    allowRadiusManuallyEdited = false;
                }
            }

            if (locationFields && window.bootstrap?.Collapse) {
                var inst = window.bootstrap.Collapse.getOrCreateInstance(locationFields, { toggle: false });
                inst.show();
            }
        });
    }

    function initLocationPicker() {
        var picker = window.UniYouth?.EventLocationPicker?.init({
            locationNameInputId: 'LocationName',
            latitudeInputId: 'Latitude',
            longitudeInputId: 'Longitude',
            mapContainerId: 'eventLocationMap',
            coordsElementId: 'eventLocationCoords',
            statusElementId: 'eventLocationStatus',
            useMyLocationButtonId: 'btnUseMyLocation',
            defaultLat: 10.7765,
            defaultLng: 106.6958,
            defaultZoom: 13,
            forwardDebounceMs: 800,
            gpsTimeoutMs: 10000
        });

        var locationFields = document.getElementById('eventLocationFields');
        if (locationFields && picker && typeof picker.refresh === 'function') {
            locationFields.addEventListener('shown.bs.collapse', function () {
                picker.refresh();
            });
        }

        initLocationPresetSync(picker, locationFields);
    }

    window.addEventListener('DOMContentLoaded', function () {
        initDatePickers();
        initLocationPicker();
    });
})();
