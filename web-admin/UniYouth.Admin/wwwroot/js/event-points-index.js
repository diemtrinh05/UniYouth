(function () {
    'use strict';

    function getModal(id) {
        var modalElement = document.getElementById(id);
        if (!modalElement || !window.bootstrap?.Modal) return null;
        return window.bootstrap.Modal.getOrCreateInstance(modalElement);
    }

    function roleDisplayName(roleType) {
        if (roleType === 'Organizer') return 'Ban tổ chức';
        if (roleType === 'Participant') return 'Người tham gia';
        if (roleType === 'Volunteer') return 'Tình nguyện viên';
        return roleType;
    }

    function editPoint(id, roleType, points, description) {
        var pointIdInput = document.getElementById('editPointId');
        var roleTypeInput = document.getElementById('editRoleType');
        var pointsInput = document.getElementById('editPoints');
        var descriptionInput = document.getElementById('editDescription');
        var roleDisplayInput = document.getElementById('editRoleDisplay');

        if (!pointIdInput || !roleTypeInput || !pointsInput || !descriptionInput || !roleDisplayInput) return;

        pointIdInput.value = id;
        roleTypeInput.value = roleType;
        pointsInput.value = points;
        descriptionInput.value = description || '';
        roleDisplayInput.value = roleDisplayName(roleType);

        getModal('editModal')?.show();
    }

    function editPointFromButton(button) {
        var id = Number(button?.dataset?.pointId || 0);
        var roleType = button?.dataset?.roleType || '';
        var points = Number(button?.dataset?.points || 0);
        var description = button?.dataset?.description || '';

        editPoint(id, roleType, points, description);
    }

    function confirmDelete(id, roleName) {
        var pointIdInput = document.getElementById('deletePointId');
        var roleNameElement = document.getElementById('deleteRoleName');

        if (!pointIdInput || !roleNameElement) return;

        pointIdInput.value = id;
        roleNameElement.textContent = roleName;

        getModal('deleteModal')?.show();
    }

    function initRowActions() {
        document.querySelectorAll('[data-event-point-edit]').forEach(function (button) {
            button.addEventListener('click', function () {
                editPointFromButton(button);
            });
        });

        document.querySelectorAll('[data-event-point-delete]').forEach(function (button) {
            button.addEventListener('click', function () {
                var id = Number(button.dataset.pointId || 0);
                var roleName = button.dataset.roleName || '';
                confirmDelete(id, roleName);
            });
        });
    }

    function initAlertDismissal() {
        window.setTimeout(function () {
            if (!window.bootstrap?.Alert) return;

            document.querySelectorAll('.alert-dismissible').forEach(function (alert) {
                window.bootstrap.Alert.getOrCreateInstance(alert).close();
            });
        }, 5000);
    }

    document.addEventListener('DOMContentLoaded', function () {
        initRowActions();
        initAlertDismissal();
    });

    window.editPoint = editPoint;
    window.editPointFromButton = editPointFromButton;
    window.confirmDelete = confirmDelete;
})();
