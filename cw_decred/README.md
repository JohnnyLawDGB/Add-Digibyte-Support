# cw_decred

`cw_decred` is a Flutter plugin that provides Decred (DCR) wallet
functionality for Cake Wallet and Monero.com. It exposes a Dart API
around the native `libdcrwallet` library so the main application can
create and manage Decred wallets, sign transactions and query
balances.

## Prerequisites

* Flutter 3.19 or newer
* Go toolchain (required to compile `libdcrwallet`)
* Platform SDKs (Android SDK/NDK, Xcode or a macOS toolchain) depending
  on the target platform

## Building the native library

This package depends on a compiled version of Decred's
`libdcrwallet`. Build scripts are provided in the repository root for
each supported platform:

```bash
scripts/android/build_decred.sh   # Android
scripts/ios/build_decred.sh       # iOS
scripts/macos/build_decred.sh     # macOS
```

Running the script will clone the Decred libwallet sources, build the
library, copy the resulting headers into `lib/api` and regenerate the
Dart bindings using `ffigen`.

## Usage

1. Add `cw_decred` and `cw_core` as dependencies in your
   `pubspec.yaml`.
2. Run `flutter pub get`.
3. Build the native library for your platform using one of the scripts
   above.
4. Import the package and use the wallet service in your Flutter code:

```dart
import 'package:cw_decred/wallet_service.dart';

final walletService = WalletService();
// Create or open a wallet using walletService
```

This project is part of the Cake Wallet app.

Copyright (c) 2024 Cake Technologies LLC.
