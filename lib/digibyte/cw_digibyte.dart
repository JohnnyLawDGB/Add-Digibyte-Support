part of 'digibyte.dart';

class CWDigibyte extends Digibyte {
  @override
  WalletService createDigibyteWalletService(
      Box<WalletInfo> walletInfoSource,
      Box<UnspentCoinsInfo> unspentCoinSource,
      bool alwaysScan,
      bool isDirect) =>
      DigibyteWalletService(
        walletInfoSource,
        unspentCoinSource,
        alwaysScan,
        isDirect,
      );

  @override
  WalletCredentials createDigibyteNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? mnemonic,
    String? passphrase,
  }) =>
      BitcoinNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createDigibyteRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      BitcoinRestoreWalletFromSeedCredentials(
        name: name,
        mnemonic: mnemonic,
        password: password,
        derivationType: DerivationType.electrum,
        derivationPath: electrum_path,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createDigibyteRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required String wif,
    WalletInfo? walletInfo,
  }) =>
      BitcoinRestoreWalletFromWIFCredentials(
        name: name,
        password: password,
        wif: wif,
        walletInfo: walletInfo,
      );

  @override
  WalletCredentials createDigibyteHardwareWalletCredentials({
    required String name,
    required HardwareAccountData accountData,
    WalletInfo? walletInfo,
  }) =>
      BitcoinRestoreWalletFromHardware(
        name: name,
        hwAccountData: accountData,
        walletInfo: walletInfo,
      );

  @override
  Object createDigibyteTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    int? feeRate,
  }) =>
      BitcoinTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                  fiatAmount: out.fiatAmount,
                  cryptoAmount: out.cryptoAmount,
                  address: out.address,
                  note: out.note,
                  sendAll: out.sendAll,
                  extractedAddress: out.extractedAddress,
                  isParsedAddress: out.isParsedAddress,
                  formattedCryptoAmount: out.formattedCryptoAmount,
                  memo: out.memo,
                ))
            .toList(),
        priority: priority as BitcoinTransactionPriority,
        feeRate: feeRate,
      );

  @override
  String getAddress(Object wallet) =>
      (wallet as DigibyteWallet).walletAddresses.address;
}
