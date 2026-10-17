import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w1xbet_admin/core/constants/sport_enum.dart';
import 'package:w1xbet_admin/core/constants/status_enum.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('fa')) {
    _load();
  }

  static const _key = 'admin_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'fa';
    emit(Locale(code));
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    emit(locale);
  }

  bool get isFa => state.languageCode == 'fa';
}

/// Lightweight FA/EN strings for admin panel.
class S {
  final Locale locale;
  const S(this.locale);

  static S of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ??
        context.read<LocaleCubit>().state;
    return S(locale);
  }

  bool get isFa => locale.languageCode == 'fa';

  String get matchesToday => isFa ? 'مسابقات امروز' : 'Matches Today';
  String get signals => isFa ? 'سیگنال‌ها' : 'Signals';
  String get settings => isFa ? 'تنظیمات' : 'Settings';
  String get home => isFa ? 'خانه' : 'Home';
  String get searchTeam => isFa ? 'جستجوی تیم...' : 'Search team...';
  String get noMatches => isFa ? 'مسابقه‌ای یافت نشد' : 'No matches found';
  String get noSignals => isFa ? 'سیگنالی وجود ندارد' : 'No signals data';
  String get live => isFa ? 'زنده' : 'Live';
  String get upcoming => isFa ? 'آینده' : 'Upcoming';
  String get finished => isFa ? 'تمام‌شده' : 'Finished';
  String get matchesCount => isFa ? 'مسابقه' : 'matches';
  String get tapToSignal =>
      isFa ? 'برای ساخت سیگنال ضربه بزنید' : 'Tap to create signal';
  String get manual => isFa ? 'دستی' : 'Manual';
  String get sportAll => isFa ? 'همه ورزش‌ها' : 'All sports';
  String get welcomeAdmin => isFa ? 'پنل مدیریت' : 'Admin panel';
  String get welcomeBack => isFa ? 'خوش آمدید' : 'Welcome back';
  String get signInToContinue =>
      isFa ? 'برای ادامه وارد شوید' : 'Sign in to continue';
  String get username => isFa ? 'نام کاربری' : 'Username';
  String get password => isFa ? 'رمز عبور' : 'Password';
  String get login => isFa ? 'ورود' : 'Login';
  String get invalidCredentials =>
      isFa ? 'نام کاربری یا رمز اشتباه است' : 'Invalid username or password';
  String get loginFailed =>
      isFa ? 'ورود ناموفق. دوباره تلاش کنید.' : 'Login failed. Please try again.';
  String get adminAccount => isFa ? 'حساب مدیر' : 'Admin account';
  String get general => isFa ? 'عمومی' : 'General';
  String get dataSync => isFa ? 'همگام‌سازی داده' : 'Data sync';
  String get tools => isFa ? 'ابزارها' : 'Tools';
  String get about => isFa ? 'درباره' : 'About';
  String get account => isFa ? 'حساب' : 'Account';
  String get changePassword => isFa ? 'تغییر رمز عبور' : 'Change password';
  String get syncNow => isFa ? 'همگام‌سازی الان' : 'Sync now';
  String get syncTennisNow =>
      isFa ? 'همگام‌سازی تنیس' : 'Sync tennis now';
  String get saveNotificationSettings =>
      isFa ? 'ذخیره تنظیمات اعلان' : 'Save notification settings';
  String get preMatchNotifications =>
      isFa ? 'اعلان قبل از مسابقه' : 'Pre-match notifications';
  String get runPreMatchNow =>
      isFa ? 'اجرای دستی اعلان قبل از مسابقه' : 'Run pre-match now';
  String get runPreMatchNowDesc => isFa
      ? 'اعلان را برای مسابقاتی که نزدیک شروع هستند، همین الان ارسال می‌کند (بر اساس تنظیمات دقیقه قبل از شروع).'
      : 'Sends notifications now for matches about to start (based on your minutes-before setting).';
  String get cleanupOldMatches =>
      isFa ? 'پاکسازی مسابقات قدیمی' : 'Cleanup old matches';
  String get cleanupOldMatchesDesc => isFa
      ? 'مسابقات دستی قدیمی‌تر از ۷ روز را از دیتابیس حذف می‌کند. این کار قابل بازگشت نیست.'
      : 'Deletes manual matches older than 7 days. This cannot be undone.';
  String get close => isFa ? 'بستن' : 'Close';
  String get runAction => isFa ? 'اجرا' : 'Run';
  String get usedToday => isFa ? 'مصرف امروز' : 'Used today';
  String get remaining => isFa ? 'باقی‌مانده' : 'Remaining';
  String get syncInterval => isFa ? 'بازه همگام‌سازی' : 'Sync interval';
  String get lastRequest => isFa ? 'آخرین درخواست' : 'Last request';
  String get lastRequestOk =>
      isFa ? 'وضعیت آخرین درخواست' : 'Last request status';
  String get success => isFa ? 'موفق' : 'OK';
  String get failed => isFa ? 'ناموفق' : 'Failed';
  String get minutesBeforeKickoff =>
      isFa ? 'دقیقه قبل از شروع' : 'Minutes before kickoff';
  String get cancel => isFa ? 'انصراف' : 'Cancel';
  String get confirm => isFa ? 'تایید' : 'Confirm';
  String get logoutConfirm =>
      isFa ? 'آیا مطمئن هستید؟' : 'Are you sure you want to logout?';
  String get passwordsMismatch =>
      isFa ? 'رمزها یکسان نیستند' : 'Passwords do not match';
  String get newPassword => isFa ? 'رمز جدید' : 'New password';
  String get confirmPassword => isFa ? 'تکرار رمز' : 'Confirm password';
  String get checking => isFa ? 'در حال بررسی...' : 'Checking...';

  String sportName(SportType sport) {
    switch (sport) {
      case SportType.all:
        return sportAll;
      case SportType.football:
        return isFa ? 'فوتبال' : 'Football';
      case SportType.handball:
        return isFa ? 'هندبال' : 'Handball';
      case SportType.hockey:
        return isFa ? 'هاکی' : 'Hockey';
      case SportType.basketball:
        return isFa ? 'بسکتبال' : 'Basketball';
      case SportType.volleyball:
        return isFa ? 'والیبال' : 'Volleyball';
      case SportType.tennis:
        return isFa ? 'تنیس' : 'Tennis';
      case SportType.beach_soccer:
        return isFa ? 'فوتبال ساحلی' : 'Beach Soccer';
      case SportType.snooker:
        return isFa ? 'اسنوکر' : 'Snooker';
      case SportType.waterpolo:
        return isFa ? 'واترپلو' : 'Waterpolo';
      case SportType.futsal:
        return isFa ? 'فوتسال' : 'Futsal';
    }
  }

  String statusFilter(MatchStatusFilter status) {
    switch (status) {
      case MatchStatusFilter.all:
        return all;
      case MatchStatusFilter.live:
        return live;
      case MatchStatusFilter.upcoming:
        return upcoming;
      case MatchStatusFilter.finished:
        return finished;
    }
  }

  String get createMatch => isFa ? 'ایجاد مسابقه' : 'Create Match';
  String get editMatch => isFa ? 'ویرایش مسابقه' : 'Edit Match';
  String get createSignal => isFa ? 'ایجاد سیگنال' : 'Create Signal';
  String get editSignal => isFa ? 'ویرایش سیگنال' : 'Edit Signal';
  String get submitSignal => isFa ? 'ثبت سیگنال' : 'Submit Signal';
  String get sendNotification => isFa ? 'ارسال اعلان' : 'Send Notification';
  String get saved => isFa ? 'با موفقیت ذخیره شد' : 'Saved successfully';
  String get sent => isFa ? 'اعلان ارسال شد' : 'Notification sent';
  String get error => isFa ? 'خطا' : 'Error';
  String get retry => isFa ? 'تلاش مجدد' : 'Retry';
  String get logout => isFa ? 'خروج' : 'Logout';
  String get language => isFa ? 'زبان' : 'Language';
  String get persian => isFa ? 'فارسی' : 'Persian';
  String get english => isFa ? 'انگلیسی' : 'English';
  String get preview => isFa ? 'پیش‌نمایش' : 'Preview';
  String get audienceAll => isFa ? 'همه کاربران' : 'All users';
  String get audienceFree => isFa ? 'کاربران FREE' : 'FREE users';
  String get audienceVip => isFa ? 'کاربران VIP' : 'VIP users';
  String get apiStatus => isFa ? 'وضعیت اتصال' : 'Connection status';
  String get connected => isFa ? 'متصل' : 'Connected';
  String get disconnected => isFa ? 'قطع' : 'Disconnected';
  String get version => isFa ? 'نسخه' : 'Version';
  String get pending => isFa ? 'در انتظار' : 'Pending';
  String get all => isFa ? 'همه' : 'All';
  String get manualCreate =>
      isFa ? 'ایجاد دستی مسابقه' : 'Create match manually';
  String get matchNotInList => isFa
      ? 'مسابقه در لیست امروز نیست'
      : 'Match not in today list';

  String get matchInfo => isFa ? 'اطلاعات مسابقه' : 'Match Info';
  String get homeTeam => isFa ? 'میزبان' : 'Home';
  String get awayTeam => isFa ? 'میهمان' : 'Away';
  String get league => isFa ? 'لیگ' : 'League';
  String get date => isFa ? 'تاریخ' : 'Date';
  String get betType => isFa ? 'نوع شرط' : 'Bet Type';
  String get betTypeHint =>
      isFa ? 'مثلاً ۱X۲، بالای ۱.۵، هندیکپ...' : 'e.g. 1X2, Over 1.5, Handicap...';
  String get betTypeRequired =>
      isFa ? 'نوع شرط الزامی است' : 'Bet type is required';
  String get betTypeTooShort =>
      isFa ? 'نوع شرط خیلی کوتاه است' : 'Bet type is too short';
  String get prediction => isFa ? 'مقدار شرط / پیش‌بینی' : 'Bet Value / Prediction';
  String get predictionHint => isFa
      ? 'مثلاً برد میزبان، بالای ۲.۵...'
      : 'e.g. Home Win, Over 2.5...';
  String get predictionRequired =>
      isFa ? 'مقدار شرط را انتخاب کنید' : 'Select a bet value';
  String get betSelectHint => isFa
      ? 'مقادیر استاندارد برای تشخیص خودکار نتیجه استفاده می‌شوند. فقط در صورت نیاز «سایر» را بزنید.'
      : 'Standard values are used for auto result detection. Use Other only if needed.';
  String get customBetType => isFa ? 'نوع شرط سفارشی' : 'Custom bet type';
  String get customBetValue => isFa ? 'مقدار شرط سفارشی' : 'Custom bet value';
  String get customLineHint =>
      isFa ? 'خط سفارشی (مثلاً ۲.۷۵)' : 'Custom line (e.g. 2.75)';
  String get selectedSummary => isFa ? 'خلاصه شرط' : 'Bet summary';
  String get draw => isFa ? 'مساوی' : 'Draw';
  String get over25 => isFa ? 'بالای ۲.۵' : 'Over 2.5';
  String get under25 => isFa ? 'زیر ۲.۵' : 'Under 2.5';
  String get signalType => isFa ? 'نوع سیگنال' : 'Signal Type';
  String get vipAnalysis =>
      isFa ? 'تحلیل VIP (اختیاری)' : 'VIP Analysis (optional)';
  String get vipAnalysisHint => isFa
      ? 'تحلیل را برای کاربران VIP بنویسید...'
      : 'Write analysis for VIP users...';
  String get showOnPicks =>
      isFa ? 'نمایش در لیست انتخاب‌ها' : 'Show on Free/VIP Picks';
  String get featuredPick => isFa ? 'انتخاب ویژه' : 'Featured pick';
  String get featuredPickHint => isFa
      ? 'اگر خاموش باشد، سیگنال به مسابقه وصل می‌ماند ولی در لیست انتخاب‌ها دیده نمی‌شود'
      : 'If off, signal stays linked to match but hidden from picks list';
  String get odds => isFa ? 'ضریب' : 'Odds';
  String get oddsHint => isFa ? 'مثلاً ۱.۸۵' : 'e.g. 1.85';
  String get oddsRequired => isFa ? 'ضریب الزامی است' : 'Odds is required';
  String get oddsInvalid =>
      isFa ? 'یک عدد معتبر وارد کنید' : 'Enter a valid number';
  String get oddsMustBeGt1 =>
      isFa ? 'ضریب باید بزرگ‌تر از ۱ باشد' : 'Odds must be greater than 1';
  String get settlementType => isFa ? 'نوع تسویه' : 'Settlement Type';
  String get settlementRegular =>
      isFa ? 'وقت معمولی' : 'Regular Time';
  String get settlementExtra =>
      isFa ? 'با احتساب وقت اضافه' : 'Including Extra Time';
  String get settlementQualification =>
      isFa ? 'صعود / واجد شرایط شدن' : 'Qualification';
  String get matchResult => isFa ? 'نتیجه سیگنال' : 'Match Result';
  String get statusWin => isFa ? 'برد' : 'WIN';
  String get statusLose => isFa ? 'باخت' : 'LOSE';
  String get statusVoid => isFa ? 'باطل' : 'VOID';
  String get signalSaved =>
      isFa ? 'سیگنال با موفقیت ذخیره شد' : 'Signal saved successfully';

  String get splashAppName => 'W1XBet Admin';
  String get splashCheckingInternet =>
      isFa ? 'بررسی اتصال اینترنت...' : 'Checking internet...';
  String get splashCheckingSupabase =>
      isFa ? 'بررسی اتصال سرور...' : 'Checking server connection...';
  String get splashLoadingData =>
      isFa ? 'دریافت داده‌های اولیه...' : 'Loading initial data...';
  String get splashPreparingHome =>
      isFa ? 'آماده‌سازی صفحه اصلی...' : 'Preparing home...';
  String get splashReady => isFa ? 'آماده!' : 'Ready!';
  String get splashNoInternet => isFa
      ? 'به اینترنت متصل نیستید. لطفاً اتصال خود را چک کنید و دوباره تلاش کنید.'
      : 'You appear to be offline. Please check your connection and try again.';
  String get splashSupabaseFailed => isFa
      ? 'الان به سرور دسترسی نداریم. اتصال اینترنت را بررسی کنید یا کمی بعد دوباره امتحان کنید.'
      : 'We couldn\'t reach the server right now. Check your connection or try again in a moment.';
  String get splashLoadFailed => isFa
      ? 'بارگذاری اطلاعات با مشکل روبه‌رو شد. لطفاً دوباره تلاش کنید.'
      : 'We couldn\'t load the data. Please try again.';
}
