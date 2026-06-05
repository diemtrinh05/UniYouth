(function () {
    'use strict';

    function bindCreateGps() {
        window.UniYouth?.LocationPresetsGps?.bind({
            buttonId: 'btnUseGpsCreate',
            latitudeInputId: 'Create_Latitude',
            longitudeInputId: 'Create_Longitude',
            addressInputId: 'Create_Address',
            statusElementId: 'gpsStatusCreate'
        });
    }

    function initCreateMap() {
        var picker = window.UniYouth?.EventLocationPicker?.init({
            locationNameInputId: 'Create_Address',
            latitudeInputId: 'Create_Latitude',
            longitudeInputId: 'Create_Longitude',
            mapContainerId: 'locationPresetMapCreate',
            coordsElementId: 'locationPresetCoordsCreate',
            statusElementId: 'locationPresetStatusCreate',
            useMyLocationButtonId: 'btnUseMyLocationCreate',
            defaultLat: 10.7765,
            defaultLng: 106.6958,
            defaultZoom: 13,
            forwardDebounceMs: 800,
            gpsTimeoutMs: 10000
        });

        var collapseEl = document.getElementById('locationPresetMapCreateCollapse');
        if (collapseEl && picker && typeof picker.refresh === 'function') {
            collapseEl.addEventListener('shown.bs.collapse', function () {
                picker.refresh();
            });
        }
    }

    function confirmDeleteLocationPreset(id, name) {
        var idInput = document.getElementById('deleteLocationPresetId');
        var nameElement = document.getElementById('deleteLocationPresetName');
        var modalElement = document.getElementById('deleteLocationPresetModal');

        if (!idInput || !nameElement || !modalElement || !window.bootstrap?.Modal) return;

        idInput.value = id;
        nameElement.textContent = name
            ? 'T\u00ean: ' + name
            : 'Preset n\u00e0y s\u1ebd b\u1ecb x\u00f3a kh\u1ecfi h\u1ec7 th\u1ed1ng.';

        window.bootstrap.Modal.getOrCreateInstance(modalElement).show();
    }

    function bindDeleteButtons() {
        document.querySelectorAll('[data-location-preset-delete]').forEach(function (button) {
            button.addEventListener('click', function () {
                var id = Number(button.dataset.locationPresetId || 0);
                var name = button.dataset.locationPresetName || '';
                confirmDeleteLocationPreset(id, name);
            });
        });
    }

    window.addEventListener('DOMContentLoaded', function () {
        bindCreateGps();
        initCreateMap();
        bindDeleteButtons();
    });

    window.confirmDeleteLocationPreset = confirmDeleteLocationPreset;
})();
