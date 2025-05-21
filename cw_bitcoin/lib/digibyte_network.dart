import 'package:bitcoin_flutter/bitcoin_flutter.dart';

final digibyteNetwork = NetworkType(
    messagePrefix: '\x19DigiByte Signed Message:\n',
    bech32: 'dgb',
    bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x1e,
    scriptHash: 0x3f,
    wif: 0x80);
