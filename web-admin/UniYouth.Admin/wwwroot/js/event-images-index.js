(function () {
    'use strict';

    const maxImageSizeBytes = 3 * 1024 * 1024;
    const fallbackImageSrc = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 320 200%22%3E%3Crect width=%22320%22 height=%22200%22 fill=%22%23f3f4f6%22/%3E%3Cpath d=%22M92 132l42-48 33 38 22-25 39 35H92z%22 fill=%22%23d1d5db%22/%3E%3Ccircle cx=%22225%22 cy=%2263%22 r=%2218%22 fill=%22%23d1d5db%22/%3E%3C/svg%3E';

    function getElement(id) {
        return document.getElementById(id);
    }

    function renderFilePreview(files) {
        const preview = getElement('filePreview');
        if (!preview) {
            return;
        }

        if (!files || files.length === 0) {
            preview.innerHTML = '';
            return;
        }

        let html = '<div class="alert alert-info small mb-0">';
        html += '<strong><i class="bi bi-info-circle me-1"></i>Đã chọn:</strong><br>';

        let totalSize = 0;
        for (let index = 0; index < files.length; index += 1) {
            const file = files[index];
            const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
            totalSize += file.size;
            html += `${index + 1}. ${file.name} (${sizeMB} MB)<br>`;
        }

        const totalSizeMB = (totalSize / (1024 * 1024)).toFixed(2);
        html += `<strong>Tổng: ${files.length} file, ${totalSizeMB} MB</strong>`;
        html += '</div>';

        preview.innerHTML = html;
    }

    function confirmDelete(imageId, imageName) {
        const imageIdInput = getElement('deleteImageId');
        const imageNameElement = getElement('deleteImageName');
        const deleteModalElement = getElement('deleteModal');
        if (!imageIdInput || !imageNameElement || !deleteModalElement) {
            return;
        }

        imageIdInput.value = imageId;
        imageNameElement.textContent = imageName;
        bootstrap.Modal.getOrCreateInstance(deleteModalElement).show();
    }

    function openEditModal(imageId, imageType, caption, displayOrder) {
        const imageIdInput = getElement('editImageId');
        const imageTypeInput = getElement('editImageType');
        const captionInput = getElement('editCaption');
        const displayOrderInput = getElement('editDisplayOrder');
        const editModalElement = getElement('editModal');
        if (!imageIdInput || !imageTypeInput || !captionInput || !displayOrderInput || !editModalElement) {
            return;
        }

        imageIdInput.value = imageId;
        imageTypeInput.value = imageType || 'Gallery';
        captionInput.value = caption || '';
        displayOrderInput.value = displayOrder || 1;
        bootstrap.Modal.getOrCreateInstance(editModalElement).show();
    }

    function bindFilePreview() {
        const filesInput = getElement('Files');
        if (!filesInput) {
            return;
        }

        filesInput.addEventListener('change', function (event) {
            renderFilePreview(event.target.files);
        });
    }

    function bindImageActions() {
        document.addEventListener('click', function (event) {
            const editBtn = event.target.closest('.js-edit-image');
            if (editBtn) {
                const imageId = Number(editBtn.getAttribute('data-image-id'));
                const imageType = editBtn.getAttribute('data-image-type');
                const caption = editBtn.getAttribute('data-caption');
                const displayOrder = Number(editBtn.getAttribute('data-display-order')) || 1;
                openEditModal(imageId, imageType, caption, displayOrder);
                return;
            }

            const deleteBtn = event.target.closest('.js-delete-image');
            if (deleteBtn) {
                const imageId = Number(deleteBtn.getAttribute('data-image-id'));
                const imageName = deleteBtn.getAttribute('data-image-name');
                confirmDelete(imageId, imageName);
            }
        });
    }

    function bindImageFallbacks() {
        document.querySelectorAll('[data-event-image-fallback]').forEach(function (image) {
            image.addEventListener('error', function () {
                image.removeAttribute('data-event-image-fallback');
                image.src = fallbackImageSrc;
            }, { once: true });
        });
    }

    function bindUploadValidation() {
        const uploadForm = getElement('uploadForm');
        if (!uploadForm) {
            return;
        }

        uploadForm.addEventListener('submit', function (event) {
            const files = getElement('Files')?.files || [];
            const imageType = getElement('ImageType')?.value;

            if (files.length === 0) {
                event.preventDefault();
                alert('Vui lòng chọn ít nhất một file hình ảnh.');
                return;
            }

            if (!imageType) {
                event.preventDefault();
                alert('Vui lòng chọn loại hình ảnh.');
                return;
            }

            for (let index = 0; index < files.length; index += 1) {
                if (files[index].size > maxImageSizeBytes) {
                    event.preventDefault();
                    alert(`File "${files[index].name}" vượt quá kích thước tối đa 3MB.`);
                    return;
                }
            }

            const uploadButton = getElement('uploadButton');
            if (uploadButton) {
                uploadButton.disabled = true;
                uploadButton.innerHTML = '<i class="bi bi-hourglass-split me-1"></i>Đang tải lên...';
            }
        });
    }

    function bindAlertDismissal() {
        window.setTimeout(function () {
            document.querySelectorAll('.alert').forEach(function (alert) {
                bootstrap.Alert.getOrCreateInstance(alert).close();
            });
        }, 5000);
    }

    document.addEventListener('DOMContentLoaded', function () {
        bindFilePreview();
        bindImageFallbacks();
        bindImageActions();
        bindUploadValidation();
        bindAlertDismissal();
    });

    window.confirmDelete = confirmDelete;
    window.openEditModal = function (imageId, imageType, caption) {
        openEditModal(imageId, imageType, caption, 1);
    };
})();
