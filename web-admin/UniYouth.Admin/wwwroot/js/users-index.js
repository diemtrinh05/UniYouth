(function () {
    'use strict';

    function initializeRolesModal() {
        const rolesModal = document.getElementById('updateRolesModal');
        if (!rolesModal) {
            return;
        }

        rolesModal.addEventListener('show.bs.modal', (event) => {
            const button = event.relatedTarget;
            if (!button) {
                return;
            }

            const userIdInput = document.getElementById('updateRolesUserId');
            const userNameEl = document.getElementById('updateRolesUserName');
            const roleSelect = document.getElementById('updateRolesRole');
            const userRole = button.getAttribute('data-user-role') || '';

            if (userIdInput) {
                userIdInput.value = button.getAttribute('data-user-id') || '';
            }

            if (userNameEl) {
                userNameEl.textContent = button.getAttribute('data-user-name') || '-';
            }

            if (roleSelect) {
                const hasRoleOption = userRole && roleSelect.querySelector(`option[value="${userRole}"]`);
                roleSelect.value = hasRoleOption ? userRole : 'CanBo';
            }
        });
    }

    function initializeStatusModal() {
        const statusModal = document.getElementById('updateStatusModal');
        if (!statusModal) {
            return;
        }

        statusModal.addEventListener('show.bs.modal', (event) => {
            const button = event.relatedTarget;
            if (!button) {
                return;
            }

            const userIdInput = document.getElementById('updateStatusUserId');
            const userNameEl = document.getElementById('updateStatusUserName');
            const statusSelect = document.getElementById('updateStatusValue');

            if (userIdInput) {
                userIdInput.value = button.getAttribute('data-user-id') || '';
            }

            if (userNameEl) {
                userNameEl.textContent = button.getAttribute('data-user-name') || '-';
            }

            if (statusSelect) {
                statusSelect.value = button.getAttribute('data-user-status') || '1';
            }
        });
    }

    function initializeCreateUserUnitSync() {
        const positionSelect = document.getElementById('createUserPositionId');
        const unitInput = document.getElementById('createUserUnitName');
        if (!positionSelect || !unitInput) {
            return;
        }

        const syncUnit = () => {
            const selectedOption = positionSelect.options[positionSelect.selectedIndex];
            unitInput.value = selectedOption?.dataset?.unitName ?? '';
        };

        positionSelect.addEventListener('change', syncUnit);
        syncUnit();
    }

    document.addEventListener('DOMContentLoaded', () => {
        initializeRolesModal();
        initializeStatusModal();
        initializeCreateUserUnitSync();
    });
})();
