
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_store.g.dart';

class AppStore = AppStoreBase with _$AppStore;

abstract class AppStoreBase with Store {
  AppStoreBase(
      {required this.authenticationStore,
      required this.walletList,
      required this.settingsStore,
      required this.nodeListStore,
      required this.themeStore});

  AuthenticationStore authenticationStore;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>? wallet;

  WalletListStore walletList;

  SettingsStore settingsStore;

  NodeListStore nodeListStore;

  ThemeStore themeStore;

  @action
  Future<void> changeCurrentWallet(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet) async {
    bool changingToSameWalletType = this.wallet?.type == wallet.type;
    this.wallet?.close(shouldCleanup: !changingToSameWalletType);
    this.wallet = wallet;
    this.wallet!.setExceptionHandler(ExceptionHandler.onError);

    if (isWalletConnectCompatibleChain(wallet.type)) {
      await getIt.get<WalletKitService>().onDispose();
      getIt.get<WalletKitService>().create();
      await getIt.get<WalletKitService>().init();
    }
    getIt.get<SharedPreferences>().setString(PreferencesKey.currentWalletName, wallet.name);
    getIt
        .get<SharedPreferences>()
        .setInt(PreferencesKey.currentWalletType, serializeToInt(wallet.type));
  }
}
