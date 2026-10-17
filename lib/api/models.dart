/// Hôpital tel que renvoyé par `GET /hospitals`.
class Hospital {
  const Hospital({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.address,
    this.emergencyPhone,
    required this.latitude,
    required this.longitude,
    required this.servicesCount,
    required this.openServicesCount,
    this.ratingAverage,
    this.reviewsCount = 0,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        id: json['id'] as int,
        name: json['name'] as String,
        city: json['city'] as String,
        region: json['region'] as String,
        address: json['address'] as String?,
        emergencyPhone: json['emergency_phone'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        servicesCount: json['services_count'] as int? ?? 0,
        openServicesCount: json['open_services_count'] as int? ?? 0,
        ratingAverage: (json['rating_average'] as num?)?.toDouble(),
        reviewsCount: json['reviews_count'] as int? ?? 0,
      );

  final int id;
  final String name;
  final String city;
  final String region;
  final String? address;

  /// Ligne directe des urgences de l'hôpital, si elle est renseignée.
  final String? emergencyPhone;
  final double? latitude;
  final double? longitude;
  final int servicesCount;
  final int openServicesCount;

  /// Note moyenne des avis des patients (`null` : pas encore d'avis).
  final double? ratingAverage;
  final int reviewsCount;
}

/// Statut d'un service à l'instant présent, calculé par le backend.
enum ServiceStatus { open, onCall, closed }

ServiceStatus _status(Map<String, dynamic> json) {
  if (json['is_open'] == true) return ServiceStatus.open;
  if (json['is_on_call'] == true) return ServiceStatus.onCall;
  return ServiceStatus.closed;
}

class TimeRange {
  const TimeRange(this.start, this.end);

  /// « HH:MM »
  final String start;
  final String end;
}

/// Service dans la fiche hôpital (`GET /hospitals/{id}`).
class ServiceSummary {
  const ServiceSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.todayHours,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    final today = json['today_hours'] as Map<String, dynamic>?;
    return ServiceSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      status: _status(json),
      todayHours: today == null ? null : TimeRange(today['opens_at'] as String, today['closes_at'] as String),
    );
  }

  final int id;
  final String name;
  final ServiceStatus status;
  final TimeRange? todayHours;
}

class HospitalDetail {
  const HospitalDetail({required this.hospital, required this.phone, required this.services});

  factory HospitalDetail.fromJson(Map<String, dynamic> json) => HospitalDetail(
        hospital: Hospital.fromJson(json),
        phone: json['phone'] as String?,
        services: (json['services'] as List<dynamic>)
            .map((item) => ServiceSummary.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final Hospital hospital;
  final String? phone;
  final List<ServiceSummary> services;
}

class ServiceHour {
  const ServiceHour({required this.dayOfWeek, required this.range});

  factory ServiceHour.fromJson(Map<String, dynamic> json) => ServiceHour(
        dayOfWeek: json['day_of_week'] as int,
        range: json['is_closed'] == true || json['opens_at'] == null
            ? null
            : TimeRange(json['opens_at'] as String, json['closes_at'] as String),
      );

  /// 0 = dimanche … 6 = samedi
  final int dayOfWeek;

  /// `null` : fermé ce jour-là.
  final TimeRange? range;
}

class OnCallShift {
  const OnCallShift({required this.date, required this.range, required this.type});

  factory OnCallShift.fromJson(Map<String, dynamic> json) => OnCallShift(
        date: DateTime.parse(json['date'] as String),
        range: TimeRange(json['starts_at'] as String, json['ends_at'] as String),
        type: json['type'] as String,
      );

  final DateTime date;
  final TimeRange range;

  /// `garde` | `weekend`
  final String type;
}

class DoctorAvailability {
  const DoctorAvailability({required this.dayOfWeek, required this.range, required this.status});

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) => DoctorAvailability(
        dayOfWeek: json['day_of_week'] as int,
        range: TimeRange(json['starts_at'] as String, json['ends_at'] as String),
        status: json['status'] as String,
      );

  final int dayOfWeek;
  final TimeRange range;

  /// `consultation` | `garde`
  final String status;
}

class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.currentStatus,
    required this.availabilities,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        specialty: json['specialty'] as String?,
        currentStatus: json['current_status'] as String?,
        availabilities: (json['availabilities'] as List<dynamic>)
            .map((item) => DoctorAvailability.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String fullName;
  final String? specialty;

  /// `consultation` | `garde` | `null` (absent en ce moment)
  final String? currentStatus;
  final List<DoctorAvailability> availabilities;
}

class ServiceDetail {
  const ServiceDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.headName,
    required this.status,
    required this.hospitalId,
    required this.hospitalName,
    this.hospitalEmergencyPhone,
    required this.hours,
    required this.onCallShifts,
    required this.doctors,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    final hospital = json['hospital'] as Map<String, dynamic>;
    return ServiceDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      headName: json['head_name'] as String?,
      status: _status(json),
      hospitalId: hospital['id'] as int,
      hospitalName: hospital['name'] as String,
      hospitalEmergencyPhone: hospital['emergency_phone'] as String?,
      hours: (json['hours'] as List<dynamic>)
          .map((item) => ServiceHour.fromJson(item as Map<String, dynamic>))
          .toList(),
      onCallShifts: (json['on_call_shifts'] as List<dynamic>)
          .map((item) => OnCallShift.fromJson(item as Map<String, dynamic>))
          .toList(),
      doctors: (json['doctors'] as List<dynamic>)
          .map((item) => Doctor.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? phone;
  final String? headName;
  final ServiceStatus status;
  final int hospitalId;
  final String hospitalName;

  /// Ligne des urgences de l'hôpital du service.
  final String? hospitalEmergencyPhone;
  final List<ServiceHour> hours;
  final List<OnCallShift> onCallShifts;
  final List<Doctor> doctors;

  TimeRange? hoursOn(int dayOfWeek) {
    for (final hour in hours) {
      if (hour.dayOfWeek == dayOfWeek) return hour.range;
    }
    return null;
  }
}
