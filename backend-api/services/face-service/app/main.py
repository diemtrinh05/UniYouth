import asyncio
import base64
import logging
import os
import time
from functools import lru_cache
from io import BytesIO
from typing import Any, Optional

import numpy as np
from fastapi import FastAPI
from PIL import Image
from pydantic import BaseModel


APP_VERSION = os.getenv("FACE_SERVICE_VERSION", "poc-v1")
PROVIDER = os.getenv("FACE_SERVICE_PROVIDER", "DeepFace")
MODEL_NAME = os.getenv("FACE_SERVICE_MODEL", "ArcFace")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("FACE_SERVICE_TIMEOUT_SECONDS", "3"))
DEFAULT_DETECTOR_BACKEND = os.getenv("FACE_SERVICE_DETECTOR_BACKEND", "opencv")
VERIFY_DETECTOR_BACKEND = os.getenv(
    "FACE_SERVICE_VERIFY_DETECTOR_BACKEND",
    DEFAULT_DETECTOR_BACKEND,
)
ENROLL_DETECTOR_BACKEND = os.getenv(
    "FACE_SERVICE_ENROLL_DETECTOR_BACKEND",
    DEFAULT_DETECTOR_BACKEND,
)
MATCH_THRESHOLD = float(os.getenv("FACE_SERVICE_MATCH_THRESHOLD", "0.85"))
REVIEW_THRESHOLD = float(os.getenv("FACE_SERVICE_REVIEW_THRESHOLD", "0.70"))
BLURRY_VARIANCE_THRESHOLD = float(os.getenv("FACE_SERVICE_BLURRY_VARIANCE_THRESHOLD", "20"))
MAX_IMAGE_DIMENSION = int(os.getenv("FACE_SERVICE_MAX_IMAGE_DIMENSION", "640"))

LIVENESS_PROVIDER = os.getenv("LIVENESS_SERVICE_PROVIDER", "PassiveLiveness")
LIVENESS_MODEL_NAME = os.getenv("LIVENESS_SERVICE_MODEL", "rule-based-passive-burst-v1")
LIVENESS_VERSION = os.getenv("LIVENESS_SERVICE_VERSION", "phase3-v1")
LIVENESS_TIMEOUT_SECONDS = float(
    os.getenv("LIVENESS_SERVICE_TIMEOUT_SECONDS", str(REQUEST_TIMEOUT_SECONDS))
)
LIVENESS_FRAME_COUNT = int(os.getenv("LIVENESS_FRAME_COUNT", "3"))
LIVENESS_MAX_FRAME_BYTES = int(os.getenv("LIVENESS_FRAME_MAX_KB", "150")) * 1024
LIVENESS_MAX_BURST_BYTES = int(os.getenv("LIVENESS_BURST_MAX_KB", "450")) * 1024
LIVENESS_PASS_THRESHOLD = float(os.getenv("LIVENESS_PASS_THRESHOLD", "0.60"))
LIVENESS_REVIEW_THRESHOLD = float(os.getenv("LIVENESS_REVIEW_THRESHOLD", "0.35"))
LIVENESS_MIN_PIXEL_DELTA = float(os.getenv("LIVENESS_MIN_PIXEL_DELTA", "0.015"))
LIVENESS_MIN_EMBEDDING_DELTA = float(os.getenv("LIVENESS_MIN_EMBEDDING_DELTA", "0.004"))
LIVENESS_MIN_BOX_DELTA = float(os.getenv("LIVENESS_MIN_BOX_DELTA", "0.002"))
LIVENESS_FACE_CROP_SIZE = int(os.getenv("LIVENESS_FACE_CROP_SIZE", "112"))
LIVENESS_MIN_BRIGHTNESS = float(os.getenv("LIVENESS_MIN_BRIGHTNESS", "0.18"))
LIVENESS_MIN_FACE_AREA_RATIO = float(os.getenv("LIVENESS_MIN_FACE_AREA_RATIO", "0.05"))
LIVENESS_MIN_FACE_CENTER_X = float(os.getenv("LIVENESS_MIN_FACE_CENTER_X", "0.24"))
LIVENESS_MAX_FACE_CENTER_X = float(os.getenv("LIVENESS_MAX_FACE_CENTER_X", "0.76"))
LIVENESS_MIN_FACE_CENTER_Y = float(os.getenv("LIVENESS_MIN_FACE_CENTER_Y", "0.18"))
LIVENESS_MAX_FACE_CENTER_Y = float(os.getenv("LIVENESS_MAX_FACE_CENTER_Y", "0.72"))
LIVENESS_DETECTOR_BACKEND = os.getenv(
    "LIVENESS_SERVICE_DETECTOR_BACKEND",
    VERIFY_DETECTOR_BACKEND,
)

STATUS_MATCHED = "Matched"
STATUS_REVIEW = "Review"
STATUS_MISMATCH = "Mismatch"
STATUS_READY = "Ready"
STATUS_NO_FACE = "NoFaceDetected"
STATUS_MULTIPLE_FACES = "MultipleFacesDetected"
STATUS_BLURRY = "BlurryImage"
STATUS_INVALID_PAYLOAD = "InvalidPayload"
STATUS_TECHNICAL_ERROR = "TechnicalError"

LIVENESS_STATUS_PASSED = "Passed"
LIVENESS_STATUS_REVIEW = "Review"
LIVENESS_STATUS_FAILED = "Failed"

ERROR_TIMEOUT = "FACE_TIMEOUT"
ERROR_INVALID_PAYLOAD = "FACE_INVALID_PAYLOAD"
ERROR_NO_FACE = "FACE_NO_FACE"
ERROR_MULTIPLE_FACES = "FACE_MULTIPLE_FACES"
ERROR_BLURRY = "FACE_BLURRY"
ERROR_TECHNICAL = "FACE_TECHNICAL_ERROR"

ERROR_LIVENESS_TIMEOUT = "LIVENESS_TIMEOUT"
ERROR_LIVENESS_INVALID_PAYLOAD = "LIVENESS_INVALID_PAYLOAD"
ERROR_LIVENESS_NO_FACE = "LIVENESS_NO_FACE"
ERROR_LIVENESS_MULTIPLE_FACES = "LIVENESS_MULTIPLE_FACES"
ERROR_LIVENESS_BLURRY = "LIVENESS_BLURRY"
ERROR_LIVENESS_TECHNICAL = "LIVENESS_TECHNICAL_ERROR"


class FaceServiceError(Exception):
    status = STATUS_TECHNICAL_ERROR
    error_code = ERROR_TECHNICAL


class InvalidPayloadError(FaceServiceError):
    status = STATUS_INVALID_PAYLOAD
    error_code = ERROR_INVALID_PAYLOAD


class NoFaceDetectedError(FaceServiceError):
    status = STATUS_NO_FACE
    error_code = ERROR_NO_FACE


class MultipleFacesDetectedError(FaceServiceError):
    status = STATUS_MULTIPLE_FACES
    error_code = ERROR_MULTIPLE_FACES


class BlurryImageError(FaceServiceError):
    status = STATUS_BLURRY
    error_code = ERROR_BLURRY


class AttendanceContextDto(BaseModel):
    eventId: int
    enableFaceVerification: bool


class ReferenceDto(BaseModel):
    faceProfileId: int
    algorithm: str
    version: Optional[str] = None
    embeddingBase64: str


class ProbeDto(BaseModel):
    imageBase64: str
    mimeType: str


class FaceVerifyRequestDto(BaseModel):
    requestId: Optional[str] = None
    userId: int
    attendanceContext: AttendanceContextDto
    reference: ReferenceDto
    probe: ProbeDto


class FaceEnrollRequestDto(BaseModel):
    requestId: Optional[str] = None
    userId: int
    probe: ProbeDto


class FaceEnrollResponseDto(BaseModel):
    provider: str
    model: str
    version: str
    status: str
    embeddingBase64: Optional[str]
    qualityScore: Optional[float]
    processingTimeMs: int
    errorCode: Optional[str] = None
    errorMessage: Optional[str] = None


class FaceVerifyResponseDto(BaseModel):
    provider: str
    model: str
    version: str
    status: str
    matched: bool
    normalizedConfidence: Optional[float]
    rawScore: Optional[float]
    qualityScore: Optional[float] = None
    threshold: float
    processingTimeMs: int
    errorCode: Optional[str] = None
    errorMessage: Optional[str] = None


class LivenessAttendanceContextDto(BaseModel):
    eventId: int
    enableFaceVerification: bool
    enableLiveness: bool


class LivenessCaptureDto(BaseModel):
    mode: str
    frameCount: int
    mimeType: str


class LivenessProbeFrameDto(BaseModel):
    frameIndex: int
    imageBase64: str
    capturedAtMs: int


class LivenessProbeDto(BaseModel):
    frames: list[LivenessProbeFrameDto]


class LivenessCheckRequestDto(BaseModel):
    requestId: Optional[str] = None
    userId: int
    attendanceContext: LivenessAttendanceContextDto
    capture: LivenessCaptureDto
    probe: LivenessProbeDto


class LivenessCheckResponseDto(BaseModel):
    provider: str
    model: str
    version: str
    status: str
    passed: Optional[bool]
    normalizedScore: Optional[float]
    rawScore: Optional[float]
    processingTimeMs: int
    reason: Optional[str] = None
    errorCode: Optional[str] = None
    errorMessage: Optional[str] = None


app = FastAPI(title="UniYouth Face Service", version=APP_VERSION)
logger = logging.getLogger("uvicorn.error")


@lru_cache(maxsize=1)
def _get_deepface() -> Any:
    try:
        from deepface import DeepFace
    except ImportError as exc:
        raise RuntimeError("DeepFace is not installed.") from exc

    return DeepFace


@lru_cache(maxsize=1)
def _warm_up_model() -> bool:
    deepface = _get_deepface()
    deepface.build_model(MODEL_NAME)
    dummy_face = np.zeros((LIVENESS_FACE_CROP_SIZE, LIVENESS_FACE_CROP_SIZE, 3), dtype=np.uint8)
    deepface.represent(
        img_path=dummy_face,
        model_name=MODEL_NAME,
        detector_backend="skip",
        enforce_detection=False,
    )
    dummy_frame = np.zeros((MAX_IMAGE_DIMENSION, MAX_IMAGE_DIMENSION, 3), dtype=np.uint8)
    warmed_detectors = set()
    for detector_backend in (
        VERIFY_DETECTOR_BACKEND,
        ENROLL_DETECTOR_BACKEND,
        LIVENESS_DETECTOR_BACKEND,
    ):
        if detector_backend in warmed_detectors:
            continue
        deepface.extract_faces(
            img_path=dummy_frame,
            detector_backend=detector_backend,
            enforce_detection=False,
            align=True,
        )
        warmed_detectors.add(detector_backend)
    return True


def _decode_embedding(embedding_base64: str) -> np.ndarray:
    try:
        embedding_bytes = base64.b64decode(embedding_base64)
    except Exception as exc:
        raise InvalidPayloadError("Reference embedding is not valid base64.") from exc

    embedding = np.frombuffer(embedding_bytes, dtype=np.float32)
    if embedding.size == 0:
        raise InvalidPayloadError("Reference embedding is empty.")
    return embedding


def _decode_image_bytes(image_base64: str, invalid_message: str) -> bytes:
    try:
        return base64.b64decode(image_base64)
    except Exception as exc:
        raise InvalidPayloadError(invalid_message) from exc


def _load_rgb_image(image_bytes: bytes, invalid_message: str) -> np.ndarray:
    try:
        with Image.open(BytesIO(image_bytes)) as image:
            rgb_image = image.convert("RGB")
            width, height = rgb_image.size
            max_dimension = max(width, height)
            if max_dimension > MAX_IMAGE_DIMENSION:
                scale = MAX_IMAGE_DIMENSION / float(max_dimension)
                rgb_image = rgb_image.resize(
                    (max(1, int(width * scale)), max(1, int(height * scale))),
                    Image.Resampling.LANCZOS,
                )

            return np.array(rgb_image)
    except Exception as exc:
        raise InvalidPayloadError(invalid_message) from exc


def _decode_image(image_base64: str) -> np.ndarray:
    image_bytes = _decode_image_bytes(image_base64, "Probe image is not valid base64.")
    return _load_rgb_image(image_bytes, "Probe image payload is invalid.")


def _compute_blur_variance(face_image: np.ndarray) -> float:
    try:
        import cv2
    except ImportError as exc:
        raise RuntimeError("opencv-python is not installed.") from exc

    scaled = face_image
    if face_image.dtype != np.uint8:
        scaled = np.clip(face_image * 255.0, 0, 255).astype(np.uint8)

    gray = cv2.cvtColor(scaled, cv2.COLOR_RGB2GRAY)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


def _extract_single_face(image: np.ndarray, detector_backend: str) -> dict[str, Any]:
    deepface = _get_deepface()

    faces = deepface.extract_faces(
        img_path=image,
        detector_backend=detector_backend,
        enforce_detection=False,
        align=True,
    )

    if not faces:
        raise NoFaceDetectedError("No face detected.")

    if len(faces) > 1:
        raise MultipleFacesDetectedError("Multiple faces detected.")

    face = faces[0]
    face_image = np.asarray(face["face"])
    blur_variance = _compute_blur_variance(face_image)
    if blur_variance < BLURRY_VARIANCE_THRESHOLD:
        raise BlurryImageError("Face image is too blurry.")

    return {
        "face_image": face_image,
        "facial_area": face.get("facial_area") or {},
        "blur_variance": blur_variance,
    }


def _extract_probe_analysis(image: np.ndarray, detector_backend: str) -> dict[str, Any]:
    deepface = _get_deepface()
    face = _extract_single_face(image, detector_backend)

    representations = deepface.represent(
        img_path=face["face_image"],
        model_name=MODEL_NAME,
        detector_backend="skip",
        enforce_detection=False,
    )

    if not representations:
        raise InvalidPayloadError("Unable to generate embedding.")

    embedding = np.asarray(representations[0]["embedding"], dtype=np.float32)
    if embedding.size == 0:
        raise InvalidPayloadError("Probe embedding is empty.")

    quality_score = _estimate_enroll_quality(face, image.shape)

    return {
        "embedding": embedding,
        "qualityScore": round(quality_score, 6),
    }


def _extract_face_sample(image: np.ndarray, detector_backend: str) -> dict[str, Any]:
    deepface = _get_deepface()
    face = _extract_single_face(image, detector_backend)

    representations = deepface.represent(
        img_path=face["face_image"],
        model_name=MODEL_NAME,
        detector_backend="skip",
        enforce_detection=False,
    )

    if not representations:
        raise InvalidPayloadError("Unable to generate liveness embedding.")

    embedding = np.asarray(representations[0]["embedding"], dtype=np.float32)
    if embedding.size == 0:
        raise InvalidPayloadError("Liveness embedding is empty.")

    crop = _resize_face_crop(face["face_image"])
    brightness = float(np.mean(crop) / 255.0)
    bbox = _normalize_facial_area(face["facial_area"], image.shape)

    return {
        "embedding": embedding,
        "crop": crop,
        "brightness": brightness,
        "bbox": bbox,
    }


def _validate_liveness_sample_quality(sample: dict[str, Any]) -> None:
    center_x, center_y, area_ratio = sample["bbox"]
    brightness = sample["brightness"]

    if (
        center_x < LIVENESS_MIN_FACE_CENTER_X
        or center_x > LIVENESS_MAX_FACE_CENTER_X
        or center_y < LIVENESS_MIN_FACE_CENTER_Y
        or center_y > LIVENESS_MAX_FACE_CENTER_Y
    ):
        raise InvalidPayloadError("Liveness face position is invalid.")

    if area_ratio < LIVENESS_MIN_FACE_AREA_RATIO:
        raise InvalidPayloadError("Liveness face size is invalid.")

    if brightness < LIVENESS_MIN_BRIGHTNESS:
        raise InvalidPayloadError("Liveness frame brightness is invalid.")


def _resize_face_crop(face_image: np.ndarray) -> np.ndarray:
    scaled = face_image
    if scaled.dtype != np.uint8:
        scaled = np.clip(scaled * 255.0, 0, 255).astype(np.uint8)

    image = Image.fromarray(scaled)
    resized = image.resize(
        (LIVENESS_FACE_CROP_SIZE, LIVENESS_FACE_CROP_SIZE),
        Image.Resampling.BILINEAR,
    )
    return np.asarray(resized, dtype=np.uint8)


def _normalize_facial_area(facial_area: dict[str, Any], image_shape: tuple[int, ...]) -> tuple[float, float, float]:
    height = max(1, int(image_shape[0]))
    width = max(1, int(image_shape[1]))

    x = float(facial_area.get("x", 0))
    y = float(facial_area.get("y", 0))
    box_width = float(facial_area.get("w", width))
    box_height = float(facial_area.get("h", height))

    center_x = (x + (box_width / 2.0)) / width
    center_y = (y + (box_height / 2.0)) / height
    area_ratio = max(0.0, min(1.0, (box_width * box_height) / float(width * height)))
    return center_x, center_y, area_ratio


def _compute_scores(reference_embedding: np.ndarray, probe_embedding: np.ndarray) -> tuple[float, float]:
    denominator = float(np.linalg.norm(reference_embedding) * np.linalg.norm(probe_embedding))
    if denominator == 0:
        raise InvalidPayloadError("Embedding norm is zero.")

    cosine_similarity = float(np.dot(reference_embedding, probe_embedding) / denominator)
    normalized_confidence = max(0.0, min(1.0, (cosine_similarity + 1.0) / 2.0))
    return cosine_similarity, normalized_confidence


def _compute_embedding_delta(first: np.ndarray, second: np.ndarray) -> float:
    denominator = float(np.linalg.norm(first) * np.linalg.norm(second))
    if denominator == 0:
        return 0.0

    cosine_similarity = float(np.dot(first, second) / denominator)
    return max(0.0, min(1.0, 1.0 - cosine_similarity))


def _compute_pixel_delta(first: np.ndarray, second: np.ndarray) -> float:
    return float(np.mean(np.abs(first.astype(np.float32) - second.astype(np.float32))) / 255.0)


def _compute_box_delta(first: tuple[float, float, float], second: tuple[float, float, float]) -> float:
    center_delta = np.sqrt(((first[0] - second[0]) ** 2) + ((first[1] - second[1]) ** 2))
    area_delta = abs(first[2] - second[2])
    return float(min(1.0, center_delta + (area_delta * 0.5)))


def _normalize_metric(value: float, full_scale: float) -> float:
    if full_scale <= 0:
        return 0.0
    return max(0.0, min(1.0, value / full_scale))


def _verify(request: FaceVerifyRequestDto) -> dict[str, Any]:
    if request.probe.mimeType.lower() != "image/jpeg":
        raise InvalidPayloadError("Unsupported mime type.")

    reference_embedding = _decode_embedding(request.reference.embeddingBase64)
    probe_image = _decode_image(request.probe.imageBase64)
    probe_analysis = _extract_probe_analysis(probe_image, VERIFY_DETECTOR_BACKEND)
    probe_embedding = np.asarray(probe_analysis["embedding"], dtype=np.float32)
    raw_score, normalized_confidence = _compute_scores(reference_embedding, probe_embedding)
    if normalized_confidence >= MATCH_THRESHOLD:
        status = STATUS_MATCHED
        matched = True
    elif normalized_confidence >= REVIEW_THRESHOLD:
        status = STATUS_REVIEW
        matched = False
    else:
        status = STATUS_MISMATCH
        matched = False

    return {
        "status": status,
        "matched": matched,
        "normalizedConfidence": round(normalized_confidence, 6),
        "rawScore": round(raw_score, 6),
        "qualityScore": probe_analysis["qualityScore"],
    }


def _estimate_enroll_quality(face: dict[str, Any], image_shape: tuple[int, ...]) -> float:
    blur_score = _normalize_metric(float(face["blur_variance"]), 120.0)
    area_ratio = _normalize_facial_area(face["facial_area"], image_shape)[2]
    area_score = _normalize_metric(area_ratio, 0.18)
    quality_score = (blur_score * 0.7) + (area_score * 0.3)
    return max(0.0, min(1.0, quality_score))


def _enroll(request: FaceEnrollRequestDto) -> dict[str, Any]:
    if request.probe.mimeType.lower() != "image/jpeg":
        raise InvalidPayloadError("Unsupported mime type.")

    image = _decode_image(request.probe.imageBase64)
    deepface = _get_deepface()
    face = _extract_single_face(image, ENROLL_DETECTOR_BACKEND)

    representations = deepface.represent(
        img_path=face["face_image"],
        model_name=MODEL_NAME,
        detector_backend="skip",
        enforce_detection=False,
    )

    if not representations:
        raise InvalidPayloadError("Unable to generate embedding.")

    embedding = np.asarray(representations[0]["embedding"], dtype=np.float32)
    if embedding.size == 0:
        raise InvalidPayloadError("Probe embedding is empty.")

    quality_score = _estimate_enroll_quality(face, image.shape)
    embedding_base64 = base64.b64encode(embedding.tobytes()).decode("ascii")

    return {
        "status": STATUS_READY,
        "embeddingBase64": embedding_base64,
        "qualityScore": round(quality_score, 6),
    }


def _validate_liveness_request(request: LivenessCheckRequestDto) -> list[np.ndarray]:
    if not request.attendanceContext.enableFaceVerification:
        raise InvalidPayloadError("Face verification must be enabled for liveness.")

    if not request.attendanceContext.enableLiveness:
        raise InvalidPayloadError("Liveness must be enabled for liveness request.")

    if request.capture.mode != "passive_auto_burst":
        raise InvalidPayloadError("Unsupported liveness capture mode.")

    if request.capture.frameCount != LIVENESS_FRAME_COUNT:
        raise InvalidPayloadError("Unsupported liveness frame count.")

    if request.capture.mimeType.lower() != "image/jpeg":
        raise InvalidPayloadError("Unsupported liveness mime type.")

    frames = request.probe.frames
    if len(frames) != LIVENESS_FRAME_COUNT:
        raise InvalidPayloadError("Liveness frame count mismatch.")

    expected_frame_indexes = list(range(LIVENESS_FRAME_COUNT))
    actual_frame_indexes = [frame.frameIndex for frame in frames]
    if actual_frame_indexes != expected_frame_indexes:
        raise InvalidPayloadError("Liveness frame indexes must be sequential.")

    previous_captured_at_ms = -1
    decoded_images: list[np.ndarray] = []
    total_payload_bytes = 0

    for frame in frames:
        if frame.capturedAtMs < 0:
            raise InvalidPayloadError("Liveness capturedAtMs must be >= 0.")

        if frame.capturedAtMs < previous_captured_at_ms:
            raise InvalidPayloadError("Liveness frames must be ordered by capturedAtMs.")

        previous_captured_at_ms = frame.capturedAtMs
        image_bytes = _decode_image_bytes(frame.imageBase64, "Liveness frame is not valid base64.")
        if len(image_bytes) > LIVENESS_MAX_FRAME_BYTES:
            raise InvalidPayloadError("Liveness frame exceeds payload guardrail.")

        total_payload_bytes += len(image_bytes)
        if total_payload_bytes > LIVENESS_MAX_BURST_BYTES:
            raise InvalidPayloadError("Liveness burst exceeds payload guardrail.")

        decoded_images.append(
            _load_rgb_image(image_bytes, "Liveness frame payload is invalid.")
        )

    return decoded_images


def _check_liveness(request: LivenessCheckRequestDto) -> dict[str, Any]:
    decoded_images = _validate_liveness_request(request)
    samples = [_extract_face_sample(image, LIVENESS_DETECTOR_BACKEND) for image in decoded_images]
    for sample in samples:
        _validate_liveness_sample_quality(sample)

    pixel_deltas = [
        _compute_pixel_delta(samples[index]["crop"], samples[index + 1]["crop"])
        for index in range(len(samples) - 1)
    ]
    embedding_deltas = [
        _compute_embedding_delta(samples[index]["embedding"], samples[index + 1]["embedding"])
        for index in range(len(samples) - 1)
    ]
    box_deltas = [
        _compute_box_delta(samples[index]["bbox"], samples[index + 1]["bbox"])
        for index in range(len(samples) - 1)
    ]
    brightness_deltas = [
        abs(samples[index]["brightness"] - samples[index + 1]["brightness"])
        for index in range(len(samples) - 1)
    ]

    avg_pixel_delta = float(np.mean(pixel_deltas))
    avg_embedding_delta = float(np.mean(embedding_deltas))
    avg_box_delta = float(np.mean(box_deltas))
    avg_brightness_delta = float(np.mean(brightness_deltas))

    motion_score = _normalize_metric(avg_pixel_delta, 0.05)
    embedding_score = _normalize_metric(avg_embedding_delta, 0.02)
    box_score = _normalize_metric(avg_box_delta, 0.02)
    brightness_score = _normalize_metric(avg_brightness_delta, 0.08)

    raw_score = (
        (motion_score * 0.45)
        + (embedding_score * 0.35)
        + (box_score * 0.10)
        + (brightness_score * 0.10)
    )
    normalized_score = max(0.0, min(1.0, raw_score))

    if (
        avg_pixel_delta < LIVENESS_MIN_PIXEL_DELTA
        and avg_embedding_delta < LIVENESS_MIN_EMBEDDING_DELTA
        and avg_box_delta < LIVENESS_MIN_BOX_DELTA
    ):
        return {
            "status": LIVENESS_STATUS_FAILED,
            "passed": False,
            "normalizedScore": round(normalized_score, 6),
            "rawScore": round(raw_score, 6),
            "reason": "Passive liveness failed due to insufficient burst variation.",
        }

    if normalized_score >= LIVENESS_PASS_THRESHOLD:
        status = LIVENESS_STATUS_PASSED
        passed = True
        reason = "Passive liveness passed."
    elif normalized_score >= LIVENESS_REVIEW_THRESHOLD:
        status = LIVENESS_STATUS_REVIEW
        passed = None
        reason = "Passive liveness requires review."
    else:
        status = LIVENESS_STATUS_FAILED
        passed = False
        reason = "Passive liveness failed."

    return {
        "status": status,
        "passed": passed,
        "normalizedScore": round(normalized_score, 6),
        "rawScore": round(raw_score, 6),
        "reason": reason,
    }


def _build_response(
    status: str,
    matched: bool,
    processing_time_ms: int,
    normalized_confidence: Optional[float] = None,
    raw_score: Optional[float] = None,
    quality_score: Optional[float] = None,
    error_code: Optional[str] = None,
    error_message: Optional[str] = None,
) -> FaceVerifyResponseDto:
    return FaceVerifyResponseDto(
        provider=PROVIDER,
        model=MODEL_NAME,
        version=APP_VERSION,
        status=status,
        matched=matched,
        normalizedConfidence=normalized_confidence,
        rawScore=raw_score,
        qualityScore=quality_score,
        threshold=MATCH_THRESHOLD,
        processingTimeMs=processing_time_ms,
        errorCode=error_code,
        errorMessage=error_message,
    )


def _build_enroll_response(
    status: str,
    processing_time_ms: int,
    embedding_base64: Optional[str] = None,
    quality_score: Optional[float] = None,
    error_code: Optional[str] = None,
    error_message: Optional[str] = None,
) -> FaceEnrollResponseDto:
    return FaceEnrollResponseDto(
        provider=PROVIDER,
        model=MODEL_NAME,
        version=APP_VERSION,
        status=status,
        embeddingBase64=embedding_base64,
        qualityScore=quality_score,
        processingTimeMs=processing_time_ms,
        errorCode=error_code,
        errorMessage=error_message,
    )


def _build_liveness_response(
    status: str,
    processing_time_ms: int,
    passed: Optional[bool] = None,
    normalized_score: Optional[float] = None,
    raw_score: Optional[float] = None,
    reason: Optional[str] = None,
    error_code: Optional[str] = None,
    error_message: Optional[str] = None,
) -> LivenessCheckResponseDto:
    return LivenessCheckResponseDto(
        provider=LIVENESS_PROVIDER,
        model=LIVENESS_MODEL_NAME,
        version=LIVENESS_VERSION,
        status=status,
        passed=passed,
        normalizedScore=normalized_score,
        rawScore=raw_score,
        processingTimeMs=processing_time_ms,
        reason=reason,
        errorCode=error_code,
        errorMessage=error_message,
    )


@app.on_event("startup")
async def warm_up_face_service() -> None:
    await asyncio.to_thread(_warm_up_model)
    logger.info(
        "face_service_warmup_complete provider=%s model=%s verify_detector=%s enroll_detector=%s liveness_detector=%s",
        PROVIDER,
        MODEL_NAME,
        VERIFY_DETECTOR_BACKEND,
        ENROLL_DETECTOR_BACKEND,
        LIVENESS_DETECTOR_BACKEND,
    )


@app.post("/internal/face/verify", response_model=FaceVerifyResponseDto)
async def verify_face(request: FaceVerifyRequestDto) -> FaceVerifyResponseDto:
    start = time.perf_counter()

    try:
        result = await asyncio.wait_for(
            asyncio.to_thread(_verify, request),
            timeout=REQUEST_TIMEOUT_SECONDS,
        )

        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.info(
            "face_verify_result request_id=%s user_id=%s event_id=%s detector=%s status=%s matched=%s confidence=%s quality=%s processing_ms=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            VERIFY_DETECTOR_BACKEND,
            result["status"],
            result["matched"],
            result["normalizedConfidence"],
            result["qualityScore"],
            processing_time_ms,
        )
        return _build_response(
            status=result["status"],
            matched=result["matched"],
            normalized_confidence=result["normalizedConfidence"],
            raw_score=result["rawScore"],
            quality_score=result["qualityScore"],
            processing_time_ms=processing_time_ms,
        )
    except asyncio.TimeoutError:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "face_verify_timeout request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            VERIFY_DETECTOR_BACKEND,
            processing_time_ms,
        )
        return _build_response(
            status=STATUS_TECHNICAL_ERROR,
            matched=False,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_TIMEOUT,
            error_message="Face verification timed out.",
        )
    except FaceServiceError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "face_verify_input_issue request_id=%s user_id=%s event_id=%s detector=%s status=%s error_code=%s processing_ms=%s message=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            VERIFY_DETECTOR_BACKEND,
            exc.status,
            exc.error_code,
            processing_time_ms,
            str(exc),
        )
        return _build_response(
            status=exc.status,
            matched=False,
            processing_time_ms=processing_time_ms,
            error_code=exc.error_code,
            error_message=str(exc),
        )
    except Exception as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.exception(
            "face_verify_unexpected_error request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            VERIFY_DETECTOR_BACKEND,
            processing_time_ms,
        )
        return _build_response(
            status=STATUS_TECHNICAL_ERROR,
            matched=False,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_TECHNICAL,
            error_message=str(exc),
        )


@app.post("/internal/face/enroll", response_model=FaceEnrollResponseDto)
async def enroll_face(request: FaceEnrollRequestDto) -> FaceEnrollResponseDto:
    start = time.perf_counter()

    try:
        result = await asyncio.wait_for(
            asyncio.to_thread(_enroll, request),
            timeout=REQUEST_TIMEOUT_SECONDS,
        )

        processing_time_ms = int((time.perf_counter() - start) * 1000)
        return _build_enroll_response(
            status=result["status"],
            embedding_base64=result["embeddingBase64"],
            quality_score=result["qualityScore"],
            processing_time_ms=processing_time_ms,
        )
    except asyncio.TimeoutError:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        return _build_enroll_response(
            status=STATUS_TECHNICAL_ERROR,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_TIMEOUT,
            error_message="Face enrollment timed out.",
        )
    except FaceServiceError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        return _build_enroll_response(
            status=exc.status,
            processing_time_ms=processing_time_ms,
            error_code=exc.error_code,
            error_message=str(exc),
        )
    except Exception as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        return _build_enroll_response(
            status=STATUS_TECHNICAL_ERROR,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_TECHNICAL,
            error_message=str(exc),
        )


@app.post("/internal/face/liveness/check", response_model=LivenessCheckResponseDto)
async def check_liveness(request: LivenessCheckRequestDto) -> LivenessCheckResponseDto:
    start = time.perf_counter()

    try:
        result = await asyncio.wait_for(
            asyncio.to_thread(_check_liveness, request),
            timeout=LIVENESS_TIMEOUT_SECONDS,
        )

        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.info(
            "liveness_check_result request_id=%s user_id=%s event_id=%s detector=%s status=%s passed=%s score=%s processing_ms=%s reason=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            result["status"],
            result["passed"],
            result["normalizedScore"],
            processing_time_ms,
            result["reason"],
        )
        return _build_liveness_response(
            status=result["status"],
            passed=result["passed"],
            normalized_score=result["normalizedScore"],
            raw_score=result["rawScore"],
            processing_time_ms=processing_time_ms,
            reason=result["reason"],
        )
    except asyncio.TimeoutError:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "liveness_check_timeout request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
        )
        return _build_liveness_response(
            status=STATUS_TECHNICAL_ERROR,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_TIMEOUT,
            error_message="Liveness verification timed out.",
            reason="Liveness verification timed out.",
        )
    except InvalidPayloadError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "liveness_check_invalid_payload request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s message=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
            str(exc),
        )
        return _build_liveness_response(
            status=STATUS_INVALID_PAYLOAD,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_INVALID_PAYLOAD,
            error_message=str(exc),
            reason=str(exc),
        )
    except NoFaceDetectedError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "liveness_check_no_face request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s message=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
            str(exc),
        )
        return _build_liveness_response(
            status=STATUS_NO_FACE,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_NO_FACE,
            error_message=str(exc),
            reason=str(exc),
        )
    except MultipleFacesDetectedError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "liveness_check_multiple_faces request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s message=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
            str(exc),
        )
        return _build_liveness_response(
            status=STATUS_MULTIPLE_FACES,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_MULTIPLE_FACES,
            error_message=str(exc),
            reason=str(exc),
        )
    except BlurryImageError as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.warning(
            "liveness_check_blurry request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s message=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
            str(exc),
        )
        return _build_liveness_response(
            status=STATUS_BLURRY,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_BLURRY,
            error_message=str(exc),
            reason=str(exc),
        )
    except Exception as exc:
        processing_time_ms = int((time.perf_counter() - start) * 1000)
        logger.exception(
            "liveness_check_unexpected_error request_id=%s user_id=%s event_id=%s detector=%s processing_ms=%s",
            request.requestId,
            request.userId,
            request.attendanceContext.eventId,
            LIVENESS_DETECTOR_BACKEND,
            processing_time_ms,
        )
        return _build_liveness_response(
            status=STATUS_TECHNICAL_ERROR,
            processing_time_ms=processing_time_ms,
            error_code=ERROR_LIVENESS_TECHNICAL,
            error_message=str(exc),
            reason="Passive liveness technical error.",
        )
