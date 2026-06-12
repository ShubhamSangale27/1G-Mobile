/// Indian states and cities for property/search dropdowns — ported from Angular.
class IndianLocations {
  static const List<MapEntry<String, List<String>>> states = [
    MapEntry('Maharashtra', ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad']),
    MapEntry('Karnataka', ['Bangalore', 'Mysore', 'Hubli', 'Mangalore']),
    MapEntry('Tamil Nadu', ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli']),
    MapEntry('Delhi', ['New Delhi', 'South Delhi', 'Dwarka', 'Rohini']),
    MapEntry('Gujarat', ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot']),
    MapEntry('Telangana', ['Hyderabad', 'Warangal', 'Nizamabad']),
    MapEntry('West Bengal', ['Kolkata', 'Howrah', 'Siliguri']),
    MapEntry('Rajasthan', ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota']),
    MapEntry('Uttar Pradesh', ['Lucknow', 'Kanpur', 'Noida', 'Ghaziabad', 'Varanasi']),
    MapEntry('Kerala', ['Thiruvananthapuram', 'Kochi', 'Kozhikode']),
    MapEntry('Punjab', ['Ludhiana', 'Amritsar', 'Mohali', 'Chandigarh']),
    MapEntry('Haryana', ['Gurgaon', 'Faridabad', 'Panipat']),
    MapEntry('Madhya Pradesh', ['Indore', 'Bhopal', 'Jabalpur']),
    MapEntry('Andhra Pradesh', ['Visakhapatnam', 'Vijayawada']),
    MapEntry('Bihar', ['Patna', 'Gaya']),
  ];

  static List<String> get stateNames => states.map((e) => e.key).toList();

  static List<String> citiesForState(String state) {
    for (final entry in states) {
      if (entry.key == state) return entry.value;
    }
    return [];
  }
}
