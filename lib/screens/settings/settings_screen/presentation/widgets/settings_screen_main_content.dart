import 'package:flutter/material.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/account_section.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/more_info_section.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

import '../../../../../utils/core/widget/shared/wallet_widget.dart';

class SettingsScreenMainContent extends StatelessWidget {
  const SettingsScreenMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(children: [
        WalletWidget(walletCharged: true, addCharged: true),
        ResponsiveVerticalSpace(24),
        AccountSection(),
        ResponsiveVerticalSpace(24),
        MoreInfoSection()
      ]),
    );
  }
}
