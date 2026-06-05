class CheckInRequestModel {
  const CheckInRequestModel({
    required this.qrToken,
    required this.latitude,
    required this.longitude,
    this.deviceInfo,
    this.clientDeviceId,
    this.faceImageBase64,
    this.faceImageMimeType,
    this.liveness,
  });

  final String qrToken;
  final double latitude;
  final double longitude;
  final String? deviceInfo;
  final String? clientDeviceId;
  final String? faceImageBase64;
  final String? faceImageMimeType;
  final LivenessCheckPayloadModel? liveness;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'qrToken': qrToken,
      'latitude': latitude,
      'longitude': longitude,
      if (deviceInfo != null && deviceInfo!.trim().isNotEmpty)
        'deviceInfo': deviceInfo!.trim(),
      if (clientDeviceId != null && clientDeviceId!.trim().isNotEmpty)
        'clientDeviceId': clientDeviceId!.trim(),
      if (faceImageBase64 != null && faceImageBase64!.trim().isNotEmpty)
        'faceImageBase64': faceImageBase64!.trim(),
      if (faceImageMimeType != null && faceImageMimeType!.trim().isNotEmpty)
        'faceImageMimeType': faceImageMimeType!.trim(),
      if (liveness != null) 'liveness': liveness!.toJson(),
    };
  }
}

class LivenessCheckPayloadModel {
  const LivenessCheckPayloadModel({
    required this.mode,
    required this.frameCount,
    required this.mimeType,
    required this.frames,
  });

  final String mode;
  final int frameCount;
  final String mimeType;
  final List<LivenessFrameModel> frames;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'frameCount': frameCount,
      'mimeType': mimeType,
      'frames': frames.map((frame) => frame.toJson()).toList(growable: false),
    };
  }
}

class LivenessFrameModel {
  const LivenessFrameModel({
    required this.frameIndex,
    required this.imageBase64,
    required this.capturedAtMs,
  });

  final int frameIndex;
  final String imageBase64;
  final int capturedAtMs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameIndex': frameIndex,
      'imageBase64': imageBase64,
      'capturedAtMs': capturedAtMs,
    };
  }
}
