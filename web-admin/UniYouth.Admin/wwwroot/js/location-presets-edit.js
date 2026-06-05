(function () {
    'use strict';

    function bindEditGps() {
        window.UniYouth?.LocationPresetsGps?.bind({
            buttonId: 'btnUseGpsEdit',
            latitudeInputId: 'Latitude',
            longitudeInputId: 'Longitude',
            addressInputId: 'Address',
            statusElementId: 'gpsStatusEdit'
        });
    }

    function initEditMap() {
        var picker = window.UniYouth?.EventLocationPicker?.init({
            locationNameInputId: 'Address',
            latitudeInputId: 'Latitude',
            longitudeInputId: 'Longitude',
            mapContainerId: 'locationPresetMapEdit',
            coordsElementId: 'locationPresetCoordsEdit',
            statusElementId: 'locationPresetStatusEdit',
            useMyLocationButtonId: 'btnUseMyLocationEdit',
            defaultLat: 10.7765,
            defaultLng: 106.6958,
            defaultZoom: 13,
            forwardDebounceMs: 800,
            gpsTimeoutMs: 10000
        });

        var collapseEl = document.getElementById('locationPresetMapEditCollapse');
        if (collapseEl && picker && typeof picker.refresh === 'function') {
            collapseEl.addEventListener('shown.bs.collapse', function () {
                picker.refresh();
            });
        }
    }

    window.addEventListener('DOMContentLoaded', function () {
        bindEditGps();
        initEditMap();
    });
})();
