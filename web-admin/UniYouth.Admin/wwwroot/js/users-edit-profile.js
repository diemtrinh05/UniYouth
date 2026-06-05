(function () {
    'use strict';

    function initializeEditUserUnitSync() {
        var positionSelect = document.getElementById('editUserPositionId');
        var unitInput = document.getElementById('editUserUnitName');
        if (!positionSelect || !unitInput) {
            return;
        }

        function syncUnit() {
            var selectedOption = positionSelect.options[positionSelect.selectedIndex];
            unitInput.value = selectedOption?.dataset?.unitName ?? '';
        }

        positionSelect.addEventListener('change', syncUnit);
        syncUnit();
    }

    document.addEventListener('DOMContentLoaded', initializeEditUserUnitSync);
})();
