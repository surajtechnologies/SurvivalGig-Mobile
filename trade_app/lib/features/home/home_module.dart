// Home feature module
// Exports all public components of the home feature

// Shared - Category (used by multiple features)
export '../../../shared/models/category.dart';

// Domain - Entities
export 'domain/entities/listing.dart';
export 'domain/entities/pagination.dart';
export 'domain/entities/current_location.dart';
export 'domain/entities/map_coordinate.dart';
export 'domain/entities/map_listing.dart';

// Domain - Repositories
export 'domain/repositories/home_repository.dart';

// Domain - UseCases
export 'domain/usecases/get_categories_usecase.dart';
export 'domain/usecases/get_listings_usecase.dart';
export 'domain/usecases/get_map_listings_usecase.dart';
export 'domain/usecases/get_nearby_listings_usecase.dart';
export 'domain/usecases/get_polygon_listings_usecase.dart';
export 'domain/usecases/get_saved_location_usecase.dart';
export 'domain/usecases/detect_home_location_usecase.dart';
export 'domain/usecases/search_address_location_usecase.dart';
export 'domain/usecases/update_location_from_pincode_usecase.dart';

// Presentation - Cubit
export 'presentation/cubit/home_cubit.dart';
export 'presentation/cubit/home_state.dart';

// Presentation - Screens
export 'presentation/screens/home_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/category_filter_chip.dart';
export 'presentation/widgets/job_card.dart';
export 'presentation/widgets/location_update_dialog.dart';
