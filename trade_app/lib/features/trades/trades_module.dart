/// Trades feature module
/// Exports all public APIs from the trades feature
library trades_module;

// Domain
export 'domain/entities/trade_detail.dart';
export 'domain/entities/trade_message.dart';
export 'domain/entities/trade_summary.dart';
export 'domain/entities/trades_page.dart';
export 'domain/entities/trades_pagination.dart';
export 'domain/repositories/trades_repository.dart';
export 'domain/usecases/accept_trade_usecase.dart';
export 'domain/usecases/confirm_trade_usecase.dart';
export 'domain/usecases/get_trade_detail_usecase.dart';
export 'domain/usecases/get_trade_messages_usecase.dart';
export 'domain/usecases/get_trades_usecase.dart';
export 'domain/usecases/reject_trade_usecase.dart';
export 'domain/usecases/send_trade_message_usecase.dart';
export 'domain/usecases/submit_trade_review_usecase.dart';

// Data
export 'data/datasources/trades_remote_datasource.dart';
export 'data/repositories/trades_repository_impl.dart';

// Presentation
export 'presentation/cubit/trade_detail_cubit.dart';
export 'presentation/cubit/trade_detail_state.dart';
export 'presentation/cubit/trades_cubit.dart';
export 'presentation/cubit/trades_state.dart';
export 'presentation/screens/trade_detail_screen.dart';
export 'presentation/screens/trades_screen.dart';
