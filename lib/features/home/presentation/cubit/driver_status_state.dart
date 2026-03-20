import 'package:flutter/foundation.dart';
import 'package:goapp/core/location/location_permission_guard.dart';

enum DriverStatus { offline, online }

const double kMinimumDutyWalletBalance = -50.0;

@immutable
class DriverState {
  final DriverStatus status;
  final bool isStatusUpdating;
  final double totalEarnings;
  final int tripsCompleted;
  final String onlineHours;
  final double walletBalance;
  final int completedRides;
  final int targetRides;
  final double rewardAmount;
  final bool isEarningsExpanded;
  final int navigateToOrdersToken;
  final LocationIssue? offlineBlockIssue;
  final int offlineBlockEventId;
  final int lowWalletBlockEventId;
  final bool showLowWalletWarning;
  final String? snackbarMessage;
  final int snackbarMessageEventId;

  const DriverState({
    this.status = DriverStatus.offline,
    this.isStatusUpdating = false,
    this.totalEarnings = 0.0,
    this.tripsCompleted = 0,
    this.onlineHours = '0h 0m',
    this.walletBalance = 120.50,
    this.completedRides = 8,
    this.targetRides = 10,
    this.rewardAmount = 80.0,
    this.isEarningsExpanded = false,
    this.navigateToOrdersToken = 0,
    this.offlineBlockIssue,
    this.offlineBlockEventId = 0,
    this.lowWalletBlockEventId = 0,
    this.showLowWalletWarning = false,
    this.snackbarMessage,
    this.snackbarMessageEventId = 0,
  });

  bool get isOnline => status == DriverStatus.online;
  bool get isOffline => status == DriverStatus.offline;
  int get remainingRides => targetRides - completedRides;
  double get progressPercentage => completedRides / targetRides;
  bool get isWalletBelowDutyThreshold =>
      walletBalance < kMinimumDutyWalletBalance;
  bool get isWalletAtOrBelowDutyThreshold =>
      walletBalance <= kMinimumDutyWalletBalance;
  double get walletShortfall => (kMinimumDutyWalletBalance - walletBalance) > 0
      ? (kMinimumDutyWalletBalance - walletBalance)
      : 0;

  DriverState copyWith({
    DriverStatus? status,
    bool? isStatusUpdating,
    double? totalEarnings,
    int? tripsCompleted,
    String? onlineHours,
    double? walletBalance,
    int? completedRides,
    int? targetRides,
    double? rewardAmount,
    bool? isEarningsExpanded,
    int? navigateToOrdersToken,
    LocationIssue? offlineBlockIssue,
    int? offlineBlockEventId,
    int? lowWalletBlockEventId,
    bool? showLowWalletWarning,
    String? snackbarMessage,
    int? snackbarMessageEventId,
    bool clearOfflineBlockIssue = false,
  }) {
    return DriverState(
      status: status ?? this.status,
      isStatusUpdating: isStatusUpdating ?? this.isStatusUpdating,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      tripsCompleted: tripsCompleted ?? this.tripsCompleted,
      onlineHours: onlineHours ?? this.onlineHours,
      walletBalance: walletBalance ?? this.walletBalance,
      completedRides: completedRides ?? this.completedRides,
      targetRides: targetRides ?? this.targetRides,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      isEarningsExpanded: isEarningsExpanded ?? this.isEarningsExpanded,
      navigateToOrdersToken:
          navigateToOrdersToken ?? this.navigateToOrdersToken,
      offlineBlockIssue: clearOfflineBlockIssue
          ? null
          : (offlineBlockIssue ?? this.offlineBlockIssue),
      offlineBlockEventId: offlineBlockEventId ?? this.offlineBlockEventId,
      lowWalletBlockEventId:
          lowWalletBlockEventId ?? this.lowWalletBlockEventId,
      showLowWalletWarning: showLowWalletWarning ?? this.showLowWalletWarning,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
      snackbarMessageEventId:
          snackbarMessageEventId ?? this.snackbarMessageEventId,
    );
  }
}
