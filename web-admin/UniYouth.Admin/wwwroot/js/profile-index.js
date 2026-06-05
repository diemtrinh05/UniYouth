(function () {
    'use strict';

    var positionSelect = document.getElementById('profilePositionId');
    var unitNameInput = document.getElementById('profileUnitName');
    var instituteNameInput = document.getElementById('profileInstituteName');
    var instituteIdInput = document.getElementById('Update_InstituteId');

    if (!positionSelect || !unitNameInput || !instituteNameInput || !instituteIdInput) {
        return;
    }

    function syncInstitute() {
        var selectedOption = positionSelect.options[positionSelect.selectedIndex];
        if (!selectedOption || !selectedOption.value) {
            unitNameInput.value = '';
            instituteNameInput.value = '\u2014';
            instituteIdInput.value = '';
            return;
        }

        unitNameInput.value = selectedOption.getAttribute('data-unit-name') || '';
        instituteNameInput.value = selectedOption.getAttribute('data-institute-name') || '\u2014';
        instituteIdInput.value = selectedOption.getAttribute('data-institute-id') || '';
    }

    positionSelect.addEventListener('change', syncInstitute);
    syncInstitute();
})();
