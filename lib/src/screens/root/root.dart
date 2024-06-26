import 'dart:async';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobx/mobx.dart';
import 'package:uni_links/uni_links.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart';

class Root extends StatefulWidget {
  Root({
    required Key key,
    required this.authenticationStore,
    required this.appStore,
    required this.child,
    required this.navigatorKey,
    required this.authService,
  }) : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthService authService;
  final Widget child;

  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> with WidgetsBindingObserver {
  RootState()
      : _isInactiveController = StreamController<bool>.broadcast(),
        _isInactive = false,
        _requestAuth = true,
        _postFrameCallback = false;

  Stream<bool> get isInactive => _isInactiveController.stream;
  StreamController<bool> _isInactiveController;
  bool _isInactive;
  bool _postFrameCallback;
  bool _requestAuth;

  StreamSubscription<Uri?>? stream;
  ReactionDisposer? _walletReactionDisposer;
  ReactionDisposer? _deepLinksReactionDisposer;
  Uri? launchUri;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    widget.authService.requireAuth().then((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _requestAuth = value);
      });
    });
    _isInactiveController = StreamController<bool>.broadcast();
    _isInactive = false;
    _postFrameCallback = false;
    super.initState();
    if (DeviceInfo.instance.isMobile) {
      initUniLinks();
    }
  }

  @override
  void dispose() {
    stream?.cancel();
    _walletReactionDisposer?.call();
    _deepLinksReactionDisposer?.call();
    super.dispose();
  }

  /// handle app links while the app is already started
  /// whether its in the foreground or in the background.
  Future<void> initUniLinks() async {
    try {
      stream = uriLinkStream.listen((Uri? uri) {
        handleDeepLinking(uri);
      });

      handleDeepLinking(await getInitialUri());
    } catch (e) {
      print(e);
    }
  }

  void handleDeepLinking(Uri? uri) async {
    if (uri == null || !mounted) return;

    launchUri = uri;

    bool requireAuth = await widget.authService.requireAuth();

    if (!requireAuth && widget.authenticationStore.state == AuthenticationState.allowed) {
      _navigateToDeepLinkScreen();
      return;
    }

    _deepLinksReactionDisposer = reaction(
      (_) => widget.authenticationStore.state,
      (AuthenticationState state) {
        if (state == AuthenticationState.allowed) {
          if (widget.appStore.wallet == null) {
            waitForWalletInstance(context, launchUri!);
          } else {
            _navigateToDeepLinkScreen();
          }
          _deepLinksReactionDisposer?.call();
          _deepLinksReactionDisposer = null;
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (isQrScannerShown) {
          return;
        }

        if (!_isInactive && widget.authenticationStore.state == AuthenticationState.allowed) {
          setState(() => _setInactive(true));
        }

        break;
      case AppLifecycleState.resumed:
        widget.authService.requireAuth().then((value) {
          setState(() {
            _requestAuth = value;
          });
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInactive && !_postFrameCallback && _requestAuth) {
      _postFrameCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamed(
          Routes.unlock,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
            if (!isAuthenticatedSuccessfully) {
              return;
            } else {
              final useTotp = widget.appStore.settingsStore.useTOTP2FA;
              final shouldUseTotp2FAToAccessWallets =
                  widget.appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;
              if (useTotp && shouldUseTotp2FAToAccessWallets) {
                _reset();
                auth.close(
                  route: Routes.totpAuthCodePage,
                  arguments: TotpAuthArgumentsModel(
                    onTotpAuthenticationFinished:
                        (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuth) {
                      if (!isAuthenticatedSuccessfully) {
                        return;
                      }
                      _reset();
                      totpAuth.close(
                        route: _getRouteToGo(),
                        arguments:
                            isWalletConnectLink ? launchUri : PaymentRequest.fromUri(launchUri),
                      );
                      launchUri = null;
                    },
                    isForSetup: false,
                    isClosable: false,
                  ),
                );
              } else {
                _reset();
                auth.close(
                  route: _getRouteToGo(),
                  arguments: isWalletConnectLink ? launchUri : PaymentRequest.fromUri(launchUri),
                );
                launchUri = null;
              }
            }
          },
        );
      });
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: widget.child,
    );
  }

  void _reset() {
    setState(() {
      _postFrameCallback = false;
      _setInactive(false);
    });
  }

  void _setInactive(bool value) {
    _isInactive = value;
    _isInactiveController.add(value);
  }

  bool _isValidPaymentUri() => launchUri?.path.isNotEmpty ?? false;

  bool get isWalletConnectLink => launchUri?.authority == 'wc';

  String? _getRouteToGo() {
    if (isWalletConnectLink) {
      if (isEVMCompatibleChain(widget.appStore.wallet!.type)) {
        _nonETHWalletErrorToast(S.current.switchToEVMCompatibleWallet);
        return null;
      }
      return Routes.walletConnectConnectionsListing;
    } else if (_isValidPaymentUri()) {
      return Routes.send;
    } else {
      return null;
    }
  }

  Future<void> _nonETHWalletErrorToast(String message) async {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void waitForWalletInstance(BuildContext context, Uri tempLaunchUri) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _walletReactionDisposer = reaction(
          (_) => widget.appStore.wallet,
          (WalletBase? wallet) {
            if (wallet != null) {
              _navigateToDeepLinkScreen();
              _walletReactionDisposer?.call();
              _walletReactionDisposer = null;
            }
          },
        );
      }
    });
  }

  void _navigateToDeepLinkScreen() {
    if (_getRouteToGo() != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamed(
          _getRouteToGo()!,
          arguments: isWalletConnectLink ? launchUri : PaymentRequest.fromUri(launchUri),
        );
        launchUri = null;
      });
    }
  }
}
