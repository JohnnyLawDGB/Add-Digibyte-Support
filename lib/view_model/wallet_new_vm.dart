import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

import '../polygon/polygon.dart';
import 'advanced_privacy_settings_view_model.dart';

part 'wallet_new_vm.g.dart';

class WalletNewVM = WalletNewVMBase with _$WalletNewVM;

abstract class WalletNewVMBase extends WalletCreationVM with Store {
  WalletNewVMBase(
    AppStore appStore,
    WalletCreationService walletCreationService,
    Box<WalletInfo> walletInfoSource,
    this.advancedPrivacySettingsViewModel,
    SeedSettingsViewModel seedSettingsViewModel, {
    required this.newWalletArguments,
  })  : selectedMnemonicLanguage = '',
        super(appStore, walletInfoSource, walletCreationService, seedSettingsViewModel,
            type: newWalletArguments!.type, isRecovery: false);

  final NewWalletArguments? newWalletArguments;
  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;

  @observable
  String selectedMnemonicLanguage;

  bool get hasLanguageSelector =>
      [WalletType.monero, WalletType.haven, WalletType.wownero].contains(type);

  bool get showLanguageSelector =>
      newWalletArguments?.mnemonic == null && hasLanguageSelector;

  bool get hasSeedType =>
      newWalletArguments?.mnemonic == null &&
      [WalletType.monero, WalletType.wownero].contains(type);

  @override
  WalletCredentials getCredentials(dynamic _options) {
    final options = _options as List<dynamic>?;
    final passphrase = seedSettingsViewModel.passphrase;
    seedSettingsViewModel.setPassphrase(null);

    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
          name: name,
          language: options!.first as String,
          password: walletPassword,
          passphrase: passphrase,
          seedType: newWalletArguments!.mnemonic != null
              ? MoneroSeedType.bip39.raw
              : (options.last as MoneroSeedType).raw,
          mnemonic: newWalletArguments!.mnemonic,
        );
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.digibyte:
        return bitcoin!.createBitcoinNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
          mnemonic: newWalletArguments!.mnemonic,
        );
      case WalletType.ethereum:
        return ethereum!.createEthereumNewWalletCredentials(
          name: name,
          password: walletPassword,
          mnemonic: newWalletArguments!.mnemonic,
          passphrase: passphrase,
        );
      case WalletType.bitcoinCash:
        return bitcoinCash!.createBitcoinCashNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
          mnemonic: newWalletArguments!.mnemonic,
        );
      case WalletType.nano:
      case WalletType.banano:
        return nano!.createNanoNewWalletCredentials(
          name: name,
          password: walletPassword,
          mnemonic: newWalletArguments!.mnemonic,
          passphrase: passphrase,
        );
      case WalletType.polygon:
        return polygon!.createPolygonNewWalletCredentials(
          name: name,
          password: walletPassword,
          mnemonic: newWalletArguments!.mnemonic,
          passphrase: passphrase,
        );
      case WalletType.solana:
        return solana!.createSolanaNewWalletCredentials(
          name: name,
          password: walletPassword,
          mnemonic: newWalletArguments!.mnemonic,
          passphrase: passphrase,
        );
      case WalletType.tron:
        return tron!.createTronNewWalletCredentials(
          name: name,
          password: walletPassword,
          mnemonic: newWalletArguments!.mnemonic,
          passphrase: passphrase,
        );
      case WalletType.wownero:
        return wownero!.createWowneroNewWalletCredentials(
          name: name,
          language: options!.first as String,
          isPolyseed: (options.last as MoneroSeedType).raw == 1,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.zano:
        return zano!.createZanoNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.decred:
        return decred!.createDecredNewWalletCredentials(name: name);
      case WalletType.none:
      case WalletType.haven:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.create(credentials, isTestnet: useTestnet);
  }
}
