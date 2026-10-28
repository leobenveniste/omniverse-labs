import 'package:flutter/material.dart';

class CountryInfo {
  final String alpha3;
  final String alpha2;
  final String nameEs;
  final String nameEn;

  const CountryInfo({
    required this.alpha3,
    required this.alpha2,
    required this.nameEs,
    required this.nameEn,
  });

  String get flagUrl => 'https://flagcdn.com/w40/${alpha2.toLowerCase()}.png';
}

class CountryHelper {
  static const List<CountryInfo> countries = [
    CountryInfo(alpha3: 'ARG', alpha2: 'ar', nameEs: 'Argentina', nameEn: 'Argentina'),
    CountryInfo(alpha3: 'USA', alpha2: 'us', nameEs: 'Estados Unidos', nameEn: 'United States'),
    CountryInfo(alpha3: 'ESP', alpha2: 'es', nameEs: 'España', nameEn: 'Spain'),
    CountryInfo(alpha3: 'ITA', alpha2: 'it', nameEs: 'Italia', nameEn: 'Italy'),
    CountryInfo(alpha3: 'FRA', alpha2: 'fr', nameEs: 'Francia', nameEn: 'France'),
    CountryInfo(alpha3: 'DEU', alpha2: 'de', nameEs: 'Alemania', nameEn: 'Germany'),
    CountryInfo(alpha3: 'GBR', alpha2: 'gb', nameEs: 'Reino Unido', nameEn: 'United Kingdom'),
    CountryInfo(alpha3: 'BRA', alpha2: 'br', nameEs: 'Brasil', nameEn: 'Brazil'),
    CountryInfo(alpha3: 'MEX', alpha2: 'mx', nameEs: 'México', nameEn: 'Mexico'),
    CountryInfo(alpha3: 'CHL', alpha2: 'cl', nameEs: 'Chile', nameEn: 'Chile'),
    CountryInfo(alpha3: 'URY', alpha2: 'uy', nameEs: 'Uruguay', nameEn: 'Uruguay'),
    CountryInfo(alpha3: 'COL', alpha2: 'co', nameEs: 'Colombia', nameEn: 'Colombia'),
    CountryInfo(alpha3: 'PER', alpha2: 'pe', nameEs: 'Perú', nameEn: 'Peru'),
    CountryInfo(alpha3: 'PRT', alpha2: 'pt', nameEs: 'Portugal', nameEn: 'Portugal'),
    CountryInfo(alpha3: 'CAN', alpha2: 'ca', nameEs: 'Canadá', nameEn: 'Canada'),
    CountryInfo(alpha3: 'JPN', alpha2: 'jp', nameEs: 'Japón', nameEn: 'Japan'),
    CountryInfo(alpha3: 'AUS', alpha2: 'au', nameEs: 'Australia', nameEn: 'Australia'),
    CountryInfo(alpha3: 'CHE', alpha2: 'ch', nameEs: 'Suiza', nameEn: 'Switzerland'),
    CountryInfo(alpha3: 'NLD', alpha2: 'nl', nameEs: 'Países Bajos', nameEn: 'Netherlands'),
    CountryInfo(alpha3: 'NZL', alpha2: 'nz', nameEs: 'Nueva Zelanda', nameEn: 'New Zealand'),
  ];

  static CountryInfo findCountry(String codeOrName) {
    final clean = codeOrName.trim().toUpperCase();
    for (final c in countries) {
      if (c.alpha3 == clean || c.alpha2.toUpperCase() == clean) {
        return c;
      }
      if (c.nameEs.toUpperCase() == clean || c.nameEn.toUpperCase() == clean) {
        return c;
      }
    }
    // Fallback: derive alpha2 from first 2 letters if 3-letter code
    final a2 = clean.length >= 2 ? clean.substring(0, 2).toLowerCase() : 'un';
    return CountryInfo(
      alpha3: clean.length >= 3 ? clean.substring(0, 3) : clean,
      alpha2: a2,
      nameEs: clean,
      nameEn: clean,
    );
  }

  static Widget buildFlag(String alpha3Or2, {double width = 22, double height = 15}) {
    final info = findCountry(alpha3Or2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5),
      child: Image.network(
        info.flagUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.3),
          child: const Center(
            child: Icon(Icons.flag_outlined, size: 12),
          ),
        ),
      ),
    );
  }
}
