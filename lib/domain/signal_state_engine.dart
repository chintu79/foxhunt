import 'rssi_processor.dart';

enum SignalState {
  veryCold,
  cold,
  warm,
  hot,
  veryHot,
  targetRange
}

class SignalStateEngine {
  SignalState determineState(double filteredRssi) {
    if (filteredRssi <= -75) return SignalState.veryCold;
    if (filteredRssi <= -66) return SignalState.cold;
    if (filteredRssi <= -56) return SignalState.warm;
    if (filteredRssi <= -46) return SignalState.hot;
    if (filteredRssi <= -40) return SignalState.veryHot;
    return SignalState.targetRange;
  }

  String getDisplayMessage(SignalState state) {
    switch (state) {
      case SignalState.veryCold:
        return "Far away";
      case SignalState.cold:
        return "Getting started";
      case SignalState.warm:
        return "Getting closer";
      case SignalState.hot:
        return "Very close";
      case SignalState.veryHot:
        return "Extremely close";
      case SignalState.targetRange:
        return "You found the zone";
    }
  }
}
