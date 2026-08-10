enum SaleOption {
  showDiscount,
  showFinalValue,
}

class SaleOptionLabel {
  const SaleOptionLabel._();

  static String text(SaleOption option) {
    switch (option) {
      case SaleOption.showDiscount:
        return 'Ver desconto';
      case SaleOption.showFinalValue:
        return 'Ver valor total a receber';
    }
  }
}
