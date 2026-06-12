import 'package:one_guntha/features/property/domain/entities/property.dart';

Property mockProperty({int id = 1, String title = 'Test Villa'}) {
  return Property(
    id: id,
    title: title,
    listingType: ListingType.sale,
    propertyType: PropertyType.house,
    price: 4500000,
    address: '123 Test Street',
    city: 'Pune',
    state: 'Maharashtra',
    bedrooms: 3,
    areaSqft: 1200,
    images: const [
      PropertyImage(
        imageUrl: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa',
        mediaType: MediaType.image,
      ),
    ],
  );
}
