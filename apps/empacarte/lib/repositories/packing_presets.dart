import 'package:uuid/uuid.dart';
import '../models/packing_item.dart';
import '../models/trip.dart';

abstract class PackingPresets {
  static const _uuid = Uuid();

  static List<PackingItem> generateSmartList({
    required String tripId,
    required TripPurpose purpose,
    required int durationDays,
    DestinationClimate climate = DestinationClimate.temperate,
    Set<DestinationClimate>? climates,
    bool hasLaundryAccess = false,
    List<String> alwaysPackItemNames = const [],
    bool isSpanish = false,
  }) {
    final List<PackingItem> items = [];

    // --- 0. ALWAYS PACK / ESSENTIALS FROM USER PROFILE ---
    for (final alwaysName in alwaysPackItemNames) {
      items.add(
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: alwaysName,
          compartment: BagCompartment.personalItem,
          category: PackingCategory.documents,
          weightKg: 0.15,
          isAlwaysPack: true,
        ),
      );
    }

    // --- 1. ESSENTIAL PERSONAL ITEM / UNDER-SEAT BACKPACK ---
    items.addAll([
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Pasaporte y Documento de Identidad' : 'Passport & Travel ID',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.documents,
        weightKg: 0.1,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Celular y Cable de Carga' : 'Smartphone & Charging Cable',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.tech,
        weightKg: 0.3,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Powerbank (10.000 mAh en equipaje de mano)' : 'Powerbank (10,000 mAh)',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.tech,
        weightKg: 0.25,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Auriculares con cancelación de ruido' : 'Noise-cancelling Headphones',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.tech,
        weightKg: 0.25,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Medicamentos personales con receta' : 'Personal Prescription Medication',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.health,
        weightKg: 0.15,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Tarjetas y Efectivo local' : 'Credit Cards & Local Cash',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.documents,
        weightKg: 0.1,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Almohadilla de viaje y antifaz' : 'Travel Pillow & Eye Mask',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.clothing,
        weightKg: 0.2,
      ),
    ]);

    // --- 2. CARRY-ON / CABIN ROLLER ---
    final shirtsCount = hasLaundryAccess ? (durationDays.clamp(2, 4)) : (durationDays.clamp(2, 7));
    final underwearCount = hasLaundryAccess ? (durationDays.clamp(3, 5)) : (durationDays + 1);

    items.addAll([
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Remeras / Camisetas ($shirtsCount un.)' : 'T-Shirts / Tops ($shirtsCount pcs)',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.clothing,
        quantity: shirtsCount,
        weightKg: 0.2 * shirtsCount,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Ropa interior y medias ($underwearCount pares)' : 'Underwear & Socks ($underwearCount pairs)',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.clothing,
        quantity: underwearCount,
        weightKg: 0.08 * underwearCount,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Adaptador Universal de Enchufes' : 'Universal Power Plug Adapter',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.tech,
        weightKg: 0.15,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Cepillo y dentífrico (< 100ml)' : 'Toothbrush & Travel Toothpaste (< 100ml)',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.toiletries,
        weightKg: 0.12,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Desodorante (< 100ml roll-on)' : 'Deodorant (< 100ml roll-on)',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.toiletries,
        weightKg: 0.1,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Zapatillas / Calzado cómodo de caminata' : 'Comfortable Sneakers',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.clothing,
        weightKg: 0.7,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Campera rompevientos / Capa liviana' : 'Light Windbreaker / Layer Jacket',
        compartment: BagCompartment.carryOn,
        category: PackingCategory.clothing,
        weightKg: 0.45,
      ),
    ]);

    // --- 3. PURPOSE-SPECIFIC ITEMS ---
    switch (purpose) {
      case TripPurpose.vacation:
        items.addAll([
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Traje de baño y toalla de secado rápido' : 'Swimsuit & Quick-dry Towel',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.clothing,
            weightKg: 0.35,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Protector solar FPS 50' : 'Sunscreen & Lip Balm SPF 50',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.toiletries,
            weightKg: 0.2,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Lentes de sol con filtro UV' : 'Sunglasses with UV Protection',
            compartment: BagCompartment.personalItem,
            category: PackingCategory.clothing,
            weightKg: 0.08,
          ),
        ]);
        break;

      case TripPurpose.business:
        items.addAll([
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Notebook de trabajo y cargador' : 'Laptop & Charger Brick',
            compartment: BagCompartment.personalItem,
            category: PackingCategory.tech,
            weightKg: 1.6,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Camisas planchadas y pantalones de vestir' : 'Ironed Dress Shirts & Slacks',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.clothing,
            weightKg: 0.8,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Tarjetas personales y libreta de notas' : 'Business Cards & Notebook',
            compartment: BagCompartment.personalItem,
            category: PackingCategory.documents,
            weightKg: 0.2,
          ),
        ]);
        break;

      case TripPurpose.hiking:
        items.addAll([
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Borcegos / Zapatillas de Trekking' : 'Trail Running / Hiking Boots',
            compartment: BagCompartment.checked,
            category: PackingCategory.clothing,
            weightKg: 1.1,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Botella o bolsa de hidratación' : 'Refillable Water Bladder / Bottle',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.health,
            weightKg: 0.25,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Repelente para insectos' : 'Insect Repellent Spray',
            compartment: BagCompartment.checked,
            category: PackingCategory.health,
            weightKg: 0.2,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Botiquín de primeros auxilios y apósitos' : 'Mini First-Aid & Blister Kit',
            compartment: BagCompartment.personalItem,
            category: PackingCategory.health,
            weightKg: 0.2,
          ),
        ]);
        break;

      case TripPurpose.city:
        items.addAll([
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Paraguas compacto de viaje' : 'Compact Travel Umbrella',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.clothing,
            weightKg: 0.25,
          ),
          PackingItem(
            id: _uuid.v4(),
            tripId: tripId,
            name: isSpanish ? 'Mochila liviana o riñonera antirrobo' : 'Daypack / Crossbody Anti-theft Bag',
            compartment: BagCompartment.carryOn,
            category: PackingCategory.clothing,
            weightKg: 0.35,
          ),
        ]);
        break;
    }

    // --- 3.5. CLIMATE-SPECIFIC GEAR (Supports single or multi-climate itinerary) ---
    final targetClimates = climates ?? {climate};

    if (targetClimates.contains(DestinationClimate.warm)) {
      items.addAll([
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Traje de baño / Malla' : 'Swimsuit / Beachwear',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.clothing,
          weightKg: 0.3,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Protector solar FPS 50+' : 'Sunscreen Lotion SPF 50+',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.toiletries,
          weightKg: 0.18,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Sandalias / Ojotas' : 'Beach Sandals / Flip-flops',
          compartment: BagCompartment.checked,
          category: PackingCategory.clothing,
          weightKg: 0.35,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Gorra o sombrero de sol' : 'Sun Hat / Visor',
          compartment: BagCompartment.personalItem,
          category: PackingCategory.clothing,
          weightKg: 0.1,
        ),
      ]);
    }

    if (targetClimates.contains(DestinationClimate.cold)) {
      items.addAll([
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Campera de abrigo pesada / Parka' : 'Heavy Winter Parka / Coat',
          compartment: BagCompartment.checked,
          category: PackingCategory.clothing,
          weightKg: 1.4,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Ropa interior térmica (remera y calza)' : 'Thermal Base Layers (top & bottom)',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.clothing,
          weightKg: 0.4,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Gorro de lana y bufanda' : 'Wool Beanie & Winter Scarf',
          compartment: BagCompartment.personalItem,
          category: PackingCategory.clothing,
          weightKg: 0.2,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Guantes térmicos para pantalla' : 'Touchscreen Winter Gloves',
          compartment: BagCompartment.personalItem,
          category: PackingCategory.clothing,
          weightKg: 0.12,
        ),
      ]);
    }

    if (targetClimates.contains(DestinationClimate.rainy)) {
      items.addAll([
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Paraguas compacto reforzado' : 'Reinforced Travel Umbrella',
          compartment: BagCompartment.personalItem,
          category: PackingCategory.clothing,
          weightKg: 0.28,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Piloto impermeable transpirable' : 'Waterproof Rain Jacket / Poncho',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.clothing,
          weightKg: 0.45,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Fundas impermeables de calzado' : 'Water-resistant Shoe Covers',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.clothing,
          weightKg: 0.15,
        ),
      ]);
    }

    if (targetClimates.contains(DestinationClimate.temperate)) {
      items.addAll([
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Cardigan o polar liviano' : 'Light Fleece / Cardigan Layer',
          compartment: BagCompartment.carryOn,
          category: PackingCategory.clothing,
          weightKg: 0.35,
        ),
        PackingItem(
          id: _uuid.v4(),
          tripId: tripId,
          name: isSpanish ? 'Pashmina o chalina liviana' : 'Lightweight Travel Scarf',
          compartment: BagCompartment.personalItem,
          category: PackingCategory.clothing,
          weightKg: 0.1,
        ),
      ]);
    }

    // --- 4. PRE-DEPARTURE HOME LOCKDOWN ---
    items.addAll([
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Cerrar llaves de paso de gas y agua' : 'Turn off Gas & Water Main Valves',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.home,
        weightKg: 0.0,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Desconectar artefactos eléctricos' : 'Unplug non-essential appliances',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.home,
        weightKg: 0.0,
      ),
      PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: isSpanish ? 'Bajar persianas y trabar ventanas' : 'Take out kitchen trash & lock windows',
        compartment: BagCompartment.personalItem,
        category: PackingCategory.home,
        weightKg: 0.0,
      ),
    ]);

    // De-duplicate items by name
    final seenNames = <String>{};
    final uniqueItems = <PackingItem>[];
    for (final it in items) {
      final normalized = it.name.trim().toLowerCase();
      if (!seenNames.contains(normalized)) {
        seenNames.add(normalized);
        uniqueItems.add(it);
      }
    }

    return uniqueItems;
  }
}
