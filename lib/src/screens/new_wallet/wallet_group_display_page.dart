import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/view_model/wallet_groups_display_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletGroupsDisplayPage extends BasePage {
  WalletGroupsDisplayPage(this.walletGroupsDisplayViewModel);

  final WalletGroupsDisplayViewModel walletGroupsDisplayViewModel;

  @override
  String get title => S.current.wallet_group;

  @override
  Widget body(BuildContext context) => WalletGroupsDisplayBody(
        walletGroupsDisplayViewModel: walletGroupsDisplayViewModel,
        currentTheme: currentTheme,
      );
}

class WalletGroupsDisplayBody extends StatelessWidget {
  WalletGroupsDisplayBody({
    required this.walletGroupsDisplayViewModel,
    required this.currentTheme,
  });

  final WalletGroupsDisplayViewModel walletGroupsDisplayViewModel;
  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Observer(
                  builder: (context) {
                    return Column(
                      children: [
                        SizedBox(height: 48),
                        if (walletGroupsDisplayViewModel.hasNoFilteredWallet) ...{
                          SizedBox(height: 16),
                          WalletGroupEmptyStateWidget(
                            currentTheme: currentTheme,
                          ),
                        },
                        ...walletGroupsDisplayViewModel.multiWalletGroups.map(
                          (walletGroup) {
                            return Observer(builder: (context) {
                              final index = walletGroupsDisplayViewModel.multiWalletGroups
                                  .indexOf(walletGroup);
                              final group = walletGroupsDisplayViewModel.multiWalletGroups[index];
                              final groupName =
                                  group.groupName ?? '${S.of(context).wallet_group} ${index + 1}';
                              return GroupedWalletExpansionTile(
                                shouldShowCurrentWalletPointer: false,
                                leadingWidget:
                                    Icon(Icons.account_balance_wallet_outlined, size: 28),
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                title: groupName,
                                childWallets: group.wallets.map((walletInfo) {
                                  return walletGroupsDisplayViewModel
                                      .convertWalletInfoToWalletListItem(walletInfo);
                                }).toList(),
                                isSelected:
                                    walletGroupsDisplayViewModel.selectedWalletGroup == group,
                                onTitleTapped: () =>
                                    walletGroupsDisplayViewModel.selectWalletGroup(group),
                                onChildItemTapped: (_) =>
                                    walletGroupsDisplayViewModel.selectWalletGroup(group),
                              );
                            });
                          },
                        ).toList(),
                        ...walletGroupsDisplayViewModel.singleWalletsList.map((singleWallet) {
                          return Observer(
                            builder: (context) {
                              final index = walletGroupsDisplayViewModel.singleWalletsList
                                  .indexOf(singleWallet);
                              final wallet = walletGroupsDisplayViewModel.singleWalletsList[index];
                              return GroupedWalletExpansionTile(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                title: wallet.name,
                                isSelected:
                                    walletGroupsDisplayViewModel.selectedSingleWallet == wallet,
                                leadingWidget: Image.asset(
                                  walletTypeToCryptoCurrency(wallet.type).iconPath!,
                                  width: 32,
                                  height: 32,
                                ),
                                onTitleTapped: () =>
                                    walletGroupsDisplayViewModel.selectSingleWallet(wallet),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
            Observer(
              builder: (context) {
                return LoadingPrimaryButton(
                  isLoading: walletGroupsDisplayViewModel.isFetchingMnemonic,
                  onPressed: () {
                    if (walletGroupsDisplayViewModel.hasNoFilteredWallet) {
                      Navigator.of(context).pushNamed(
                        Routes.newWallet,
                        arguments: NewWalletArguments(type: walletGroupsDisplayViewModel.type),
                      );
                    } else {
                      onTypeSelected(context);
                    }
                  },
                  text: walletGroupsDisplayViewModel.hasNoFilteredWallet
                      ? S.of(context).create_new_seed
                      : S.of(context).seed_language_next,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isDisabled: !walletGroupsDisplayViewModel.hasNoFilteredWallet
                      ? (walletGroupsDisplayViewModel.selectedWalletGroup == null &&
                          walletGroupsDisplayViewModel.selectedSingleWallet == null)
                      : false,
                );
              },
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> onTypeSelected(BuildContext context) async {
    final mnemonic = await walletGroupsDisplayViewModel.getSelectedWalletMnemonic();
    Navigator.of(context).pushNamed(
      Routes.newWallet,
      arguments: NewWalletArguments(
        type: walletGroupsDisplayViewModel.type,
        mnemonic: mnemonic,
        isChildWallet: true,
      ),
    );
  }
}

class WalletGroupEmptyStateWidget extends StatelessWidget {
  const WalletGroupEmptyStateWidget({required this.currentTheme, super.key});

  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CakeImageWidget(
          imageUrl: currentTheme.isDark
              ? 'assets/images/wallet_group_empty_dark.png'
              : 'assets/images/wallet_group_empty_light.png',
          height: 200,
        ),
        SizedBox(height: 60),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${S.of(context).wallet_group_empty_state_text_one} ',
              ),
              TextSpan(
                text: '${S.of(context).create_new_seed} ',
                style:
                    Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: S.of(context).wallet_group_empty_state_text_two),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                height: 1.5,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
