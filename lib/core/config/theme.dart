import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color.fromARGB(255, 13, 102, 237);
  static const primaryForeground = Color.fromARGB(255, 26, 113, 244);
  static const backgroundDark = Color.fromARGB(255, 13, 17, 31);
  static const surfaceDark = Color.fromARGB(255, 8, 12, 23);
  static const cardOverlay = Color.fromARGB(13, 121, 154, 255);
  static const disabledBackground = Color.fromARGB(13, 179, 218, 255);

  static const foregroundColor = Colors.white;
  static const secondaryTextColor = Colors.grey;

  static const none = Colors.transparent;

  static const successColor = Color(0xFF00bc7d);
  static const errorColor = Color(0xFFff2056);
  static const warningColor = Color(0xFFfd9a00);
  static const infoColor = AppColors.primary;
  static const finishColor = Color(0xFF615fff);
}

class AppTheme {
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.foregroundColor,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: AppColors.foregroundColor,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle contentStyle = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle smallContentStyle = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const double RADIUS = 16.0;
  static const Radius BORDER_RADIUS = Radius.circular(RADIUS);

  static AppBarTheme APP_BAR_THEME = const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    // toolbarHeight: 100,
    shadowColor: Colors.transparent,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: AppColors.foregroundColor,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: AppColors.foregroundColor),
    actionsIconTheme: IconThemeData(color: AppColors.foregroundColor),
    toolbarTextStyle: TextStyle(
      color: AppColors.foregroundColor,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.backgroundDark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  static const SnackBarThemeData SNACK_BAR_THEME = SnackBarThemeData(
    backgroundColor: AppColors.backgroundDark,
    contentTextStyle: TextStyle(color: AppColors.foregroundColor),
    actionTextColor: AppColors.primaryForeground,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(BORDER_RADIUS),
      side: BorderSide.none,
    ),
  );

  static const TabBarTheme TAB_BAR_THEME = TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.foregroundColor,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: Colors.transparent,
    indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 2.0)),
  );

  static const BottomNavigationBarThemeData BOTTOM_NAVIGATION_BAR_THEME =
      BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.foregroundColor,
        elevation: 0,
      );
  static const InputDecorationTheme INPUT_THEME = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardOverlay,
    labelStyle: TextStyle(color: AppColors.foregroundColor, fontWeight: FontWeight.bold),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(BORDER_RADIUS),
      borderSide: BorderSide.none,
    ),
  );

  static PopupMenuThemeData POPUP_MENU_THEME = PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RADIUS),
      side: BorderSide.none,
    ),
    color: AppColors.backgroundDark,
  );
  static DropdownMenuThemeData DROPDOWN_MENU_THEME = DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.backgroundDark),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(RADIUS), side: BorderSide.none),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(BORDER_RADIUS),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static DatePickerThemeData DATEPICKER_THEME = DatePickerThemeData(
    backgroundColor: AppColors.backgroundDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RADIUS),
      side: BorderSide.none,
    ),
  );

  static TimePickerThemeData TIMEPICKER_THEME = TimePickerThemeData(
    backgroundColor: AppColors.backgroundDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RADIUS),
      side: BorderSide.none,
    ),
  );

  static ElevatedButtonThemeData BUTTON_THEME = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      disabledBackgroundColor: AppColors.disabledBackground,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.foregroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RADIUS)),
    ),
  );

  static DialogTheme DIALOG_THEME = DialogTheme(
    backgroundColor: AppColors.surfaceDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RADIUS),
      side: BorderSide(color: AppColors.cardOverlay, width: 1.0),
    ),
  );

  static CardTheme CARD_THEME = CardTheme(
    elevation: 0,
    color: AppColors.cardOverlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RADIUS),
      side: BorderSide.none,
    ),
  );

  static IconButtonThemeData ICON_BUTTON_THEME = IconButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(RADIUS), side: BorderSide.none),
      ),
    ),
  );
  static FloatingActionButtonThemeData FLOATING_BUTTON_THEME = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.foregroundColor,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RADIUS)),
  );

  static ThemeData build() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: Colors.transparent,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      switchTheme: const SwitchThemeData(),
      appBarTheme: APP_BAR_THEME,
      snackBarTheme: SNACK_BAR_THEME,
      tabBarTheme: TAB_BAR_THEME,
      bottomNavigationBarTheme: BOTTOM_NAVIGATION_BAR_THEME,
      inputDecorationTheme: INPUT_THEME,
      popupMenuTheme: POPUP_MENU_THEME,
      dropdownMenuTheme: DROPDOWN_MENU_THEME,
      datePickerTheme: DATEPICKER_THEME,
      timePickerTheme: TIMEPICKER_THEME,
      elevatedButtonTheme: BUTTON_THEME,
      dialogTheme: DIALOG_THEME,
      cardTheme: CARD_THEME,
      iconButtonTheme: ICON_BUTTON_THEME,
      floatingActionButtonTheme: FLOATING_BUTTON_THEME,
    );
  }
}
