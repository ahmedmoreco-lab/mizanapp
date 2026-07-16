import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  static const _strings = <String, Map<String, String>>{
    'en': {
      // General
      'appTitle': 'Mizan',
      'cancel': 'Cancel',
      'save': 'Save',
      'retry': 'Retry',
      'ok': 'OK',
      'settings': 'Settings',
      'logout': 'Logout',
      'language': 'Language',
      'english': 'English',
      'arabic': 'عربي',

      // Auth
      'email': 'Email',
      'enterEmail': 'Enter your email',
      'password': 'Password',
      'enterPassword': 'Enter your password',
      'signIn': 'Sign In',
      'welcomeBack': 'Welcome back. Please sign in to continue.',
      'forgotPassword': 'Forgot Password?',
      'needAccount': 'Need an account? Create one',
      'haveAccount': 'Already have an account? Log in',
      'loginError': 'Login Error',
      'createAccount': 'Create Account',
      'signUp': 'Sign Up',
      'fillDetails': 'Fill in your details to get started.',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'age': 'Age',
      'gender': 'Gender',
      'role': 'Role',
      'elderRole': 'Elder',
      'trustedContactRole': 'Trusted Contact',
      'startWithPremium': 'Start with Premium',
      'premiumSubtitle': 'Up to 5 trusted contacts & more.',
      'required': 'Required',
      'enterValidAge': 'Enter a valid age',
      'enterValidEmail': 'Enter a valid email',
      'passwordTooShort': 'Password must be at least 6 characters',
      'selectGender': 'Please select a gender',

      // Elder Home
      'myDashboard': 'My Dashboard',
      'howAreYouFeeling': 'How are you feeling today?',
      'imOk': "I'M OK",
      'sos': 'SOS',
      'youAreSafe': 'You are Safe ✓',
      'noCheckInYet': 'No check-in recorded yet',
      'missedCheckIn': 'Missed Check-in',
      'trustedContacts': 'Trusted Contacts',
      'noTrustedContact': 'No Trusted Contact',
      'requiredForSafety': '⚠️ Required for safety alerts!',
      'safetyNetworkComplete': 'Safety network complete',
      'tapToManage': 'Tap to manage · Add up to',
      'confirmEmergency': 'Confirm Emergency',
      'emergencyAlertText':
          'This will immediately alert your Trusted Contacts.\n\nAre you sure?',
      'yesSendSOS': 'Yes, Send SOS',
      'emergencyAlertSent': '🚨 Emergency Alert Sent!',
      'checkInSuccess': '✅ Check-in successful!',
      'addContactFirst': 'Please add a trusted contact first',
      'accountSettings': 'Account Settings',
      'checkInReminders': 'Check-in Reminders',
      'reminders': 'Reminders:',
      'premiumBanner': 'Premium: Smart escalation · 5 contacts · Custom reminders',

      // Contact Home
      'monitoringDashboard': 'Monitoring Dashboard',
      'noEldersLinked': 'No Elders Linked',
      'noEldersDesc': 'an elder must add your email in their app to link their account to yours.',
      'lastActive': 'Last active:',
      'weeklySafetyInsights': 'Weekly Safety Insights',
      'last7Days': 'Last 7 days:',
      'safe': 'safe',
      'missed': 'Missed',
      'days': 'days',
      'setAlertThreshold': 'Set Alert Threshold',
      'alertMeIf': 'Alert me if',
      'missesCheckIn': 'misses a check-in for more than:',

      // Settings
      'profile': 'Profile',
      'displayName': 'Display Name',
      'enterName': 'Enter your name',
      'updateName': 'Update Name',
      'changePassword': 'Change Password',
      'currentPassword': 'Current Password',
      'enterCurrentPassword': 'Enter your current password',
      'newPassword': 'New Password',
      'atLeast6Chars': 'At least 6 characters',
      'dangerZone': 'Danger Zone',
      'deleteAccount': 'Delete My Account',
      'deleteAccountWarning':
          'Deleting your account is permanent and cannot be undone. All your data will be erased.',
      'upgradeToP': 'Upgrade to Premium',
      'unlockPremium': 'Unlock smart escalation & multiple contacts.',
      'premiumSubbed': 'Premium Subscribed',
      'view': 'View',

      // SOS Active State
      'sosAlertActive': 'SOS Alert Active',
      'helpOnTheWay': 'Your emergency contact has been alerted. Help is on the way.',
      'imSafeNow': "I'm Safe Now",
      'tapWhenSafe': 'Tap to let your contact know you are okay',
      'areYouSafe': 'Are you safe?',
      'alertOverText': 'This will let your emergency contact know the alert is over and you are okay.',
      'yesSafe': "Yes, I'm Safe",
      'couldNotCancel': 'Could not cancel the alert. Please try again.',

      // Background Safety Monitor
      'monitorTitle': '🛡 Background Safety Monitor',
      'monitorOnSub': 'Active — watching for activity',
      'monitorOffSub': 'Turn on for an extra safety layer',
      'monitorExplain':
          'When ON, Mizan quietly watches for phone activity. If it notices no activity for a long time, it will check on you first before alerting your contact.',
      'monitorPermNotifOk': 'Notifications allowed',
      'monitorPermNotifMissing': 'Please allow notifications',
      'monitorPermBatteryOk': 'Battery optimization disabled',
      'monitorPermBatteryMissing': 'Please disable battery optimization',
      'monitorNotifTitle': 'Mizan is keeping you safe',
      'monitorNotifBody': 'Background safety check is active.',
      'monitorChannelName': 'Safety Monitor',
      'monitorChannelDesc':
          'Keeps the background safety monitor running so Mizan can detect inactivity.',
      'monitorNotifPermissionRequired':
          'Notification permission is required to keep you safe.',
      'monitorCouldNotStart':
          'Could not start the safety monitor. Please try again.',
    },
    'ar': {
      // General
      'appTitle': 'Mizan',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'retry': 'إعادة المحاولة',
      'ok': 'حسناً',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'عربي',

      // Auth
      'email': 'البريد الإلكتروني',
      'enterEmail': 'أدخل بريدك الإلكتروني',
      'password': 'كلمة المرور',
      'enterPassword': 'أدخل كلمة المرور',
      'signIn': 'تسجيل الدخول',
      'welcomeBack': 'مرحباً بعودتك. يرجى تسجيل الدخول للمتابعة.',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'needAccount': 'ليس لديك حساب؟ أنشئ واحداً',
      'haveAccount': 'لديك حساب بالفعل؟ سجل الدخول',
      'loginError': 'خطأ في تسجيل الدخول',
      'createAccount': 'إنشاء حساب',
      'signUp': 'إنشاء حساب',
      'fillDetails': 'أدخل بياناتك للبدء.',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'age': 'العمر',
      'gender': 'الجنس',
      'role': 'الدور',
      'elderRole': 'مسن',
      'trustedContactRole': 'جهة اتصال موثوقة',
      'startWithPremium': 'البدء بالبريميوم',
      'premiumSubtitle': 'حتى 5 جهات اتصال موثوقة والمزيد.',
      'required': 'مطلوب',
      'enterValidAge': 'أدخل عمراً صحيحاً',
      'enterValidEmail': 'أدخل بريداً إلكترونياً صحيحاً',
      'passwordTooShort': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'selectGender': 'يرجى اختيار الجنس',

      // Elder Home
      'myDashboard': 'لوحتي',
      'howAreYouFeeling': 'كيف حالك اليوم؟',
      'imOk': 'بخير',
      'sos': 'استغاثة',
      'youAreSafe': 'أنت بأمان ✓',
      'noCheckInYet': 'لم يتم تسجيل أي تسجيل حضور بعد',
      'missedCheckIn': 'تسجيل حضور مفقود',
      'trustedContacts': 'جهات الاتصال الموثوقة',
      'noTrustedContact': 'لا توجد جهة اتصال موثوقة',
      'requiredForSafety': '⚠️ مطلوب لتنبيهات الأمان!',
      'safetyNetworkComplete': 'شبكة الأمان مكتملة',
      'tapToManage': 'اضغط للإدارة · أضف حتى',
      'confirmEmergency': 'تأكيد الطوارئ',
      'emergencyAlertText':
          'سيتم تنبيه جهات الاتصال الموثوقة فورًا.\n\nهل أنت متأكد؟',
      'yesSendSOS': 'نعم، إرسال استغاثة',
      'emergencyAlertSent': '🚨 تم إرسال تنبيه الطوارئ!',
      'checkInSuccess': '✅ تم تسجيل الحضور بنجاح!',
      'addContactFirst': 'يرجى إضافة جهة اتصال موثوقة أولاً',
      'accountSettings': 'إعدادات الحساب',
      'checkInReminders': 'تذكيرات تسجيل الحضور',
      'reminders': 'التذكيرات:',
      'premiumBanner': 'بريميوم: تصعيد ذكي · 5 جهات اتصال · تذكيرات مخصصة',

      // Contact Home
      'monitoringDashboard': 'لوحة المراقبة',
      'noEldersLinked': 'لم يتم ربط أي مسن',
      'noEldersDesc': 'يجب على المسن إضافة بريدك الإلكتروني في تطبيقه لربط حسابه بحسابك.',
      'lastActive': 'آخر نشاط:',
      'weeklySafetyInsights': 'إحصائيات الأمان الأسبوعية',
      'last7Days': 'آخر 7 أيام:',
      'safe': 'آمن',
      'missed': 'فائت',
      'days': 'أيام',
      'setAlertThreshold': 'تعيين حد التنبيه',
      'alertMeIf': 'نبهني إذا',
      'missesCheckIn': 'فاته تسجيل الحضور لأكثر من:',

      // Settings
      'profile': 'الملف الشخصي',
      'displayName': 'الاسم المعروض',
      'enterName': 'أدخل اسمك',
      'updateName': 'تحديث الاسم',
      'changePassword': 'تغيير كلمة المرور',
      'currentPassword': 'كلمة المرور الحالية',
      'enterCurrentPassword': 'أدخل كلمة المرور الحالية',
      'newPassword': 'كلمة المرور الجديدة',
      'atLeast6Chars': '6 أحرف على الأقل',
      'dangerZone': 'منطقة الخطر',
      'deleteAccount': 'حذف حسابي',
      'deleteAccountWarning':
          'حذف حسابك نهائي ولا يمكن التراجع عنه. ستُمحى جميع بياناتك.',
      'upgradeToP': 'الترقية إلى بريميوم',
      'unlockPremium': 'افتح التصعيد الذكي وجهات اتصال متعددة.',
      'premiumSubbed': 'مشترك في بريميوم',
      'view': 'عرض',

      // SOS Active State
      'sosAlertActive': 'تنبيه الاستغاثة نشط',
      'helpOnTheWay': 'تم تنبيه جهة اتصال الطوارئ. المساعدة في الطريق.',
      'imSafeNow': 'أنا بأمان الآن',
      'tapWhenSafe': 'اضغط لإعلام جهة الاتصال أنك بخير',
      'areYouSafe': 'هل أنت بأمان؟',
      'alertOverText': 'سيُعلم هذا جهة اتصال الطوارئ بأن التنبيه انتهى وأنك بخير.',
      'yesSafe': 'نعم، أنا بأمان',
      'couldNotCancel': 'تعذر إلغاء التنبيه. يرجى المحاولة مجدداً.',

      // Background Safety Monitor
      'monitorTitle': '🛡 مراقب الأمان في الخلفية',
      'monitorOnSub': 'نشط — يراقب النشاط',
      'monitorOffSub': 'فعّله لطبقة حماية إضافية',
      'monitorExplain':
          'عند التفعيل، يراقب Mizan نشاط الهاتف بهدوء. إذا لم يلاحظ أي نشاط لفترة طويلة، سيطمئن عليك أولاً قبل تنبيه جهة الاتصال.',
      'monitorPermNotifOk': 'الإشعارات مسموح بها',
      'monitorPermNotifMissing': 'يرجى السماح بالإشعارات',
      'monitorPermBatteryOk': 'تم تعطيل تحسين البطارية',
      'monitorPermBatteryMissing': 'يرجى تعطيل تحسين البطارية',
      'monitorNotifTitle': 'Mizan يحافظ على سلامتك',
      'monitorNotifBody': 'فحص الأمان في الخلفية نشط.',
      'monitorChannelName': 'مراقب الأمان',
      'monitorChannelDesc':
          'يبقي مراقب الأمان في الخلفية يعمل حتى يتمكن Mizan من اكتشاف الخمول.',
      'monitorNotifPermissionRequired':
          'إذن الإشعارات مطلوب للحفاظ على سلامتك.',
      'monitorCouldNotStart': 'تعذر بدء مراقب الأمان. يرجى المحاولة مرة أخرى.',
    },
  };

  String _t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;

  // General
  String get appTitle => _t('appTitle');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get retry => _t('retry');
  String get ok => _t('ok');
  String get settings => _t('settings');
  String get logout => _t('logout');
  String get language => _t('language');
  String get english => _t('english');
  String get arabic => _t('arabic');

  // Auth
  String get email => _t('email');
  String get enterEmail => _t('enterEmail');
  String get password => _t('password');
  String get enterPassword => _t('enterPassword');
  String get signIn => _t('signIn');
  String get welcomeBack => _t('welcomeBack');
  String get forgotPassword => _t('forgotPassword');
  String get needAccount => _t('needAccount');
  String get haveAccount => _t('haveAccount');
  String get loginError => _t('loginError');
  String get createAccount => _t('createAccount');
  String get signUp => _t('signUp');
  String get fillDetails => _t('fillDetails');
  String get firstName => _t('firstName');
  String get lastName => _t('lastName');
  String get age => _t('age');
  String get gender => _t('gender');
  String get role => _t('role');
  String get elderRole => _t('elderRole');
  String get trustedContactRole => _t('trustedContactRole');
  String get startWithPremium => _t('startWithPremium');
  String get premiumSubtitle => _t('premiumSubtitle');
  String get required => _t('required');
  String get enterValidAge => _t('enterValidAge');
  String get enterValidEmail => _t('enterValidEmail');
  String get passwordTooShort => _t('passwordTooShort');
  String get selectGender => _t('selectGender');

  // Elder Home
  String get myDashboard => _t('myDashboard');
  String get howAreYouFeeling => _t('howAreYouFeeling');
  String get imOk => _t('imOk');
  String get sos => _t('sos');
  String get youAreSafe => _t('youAreSafe');
  String get noCheckInYet => _t('noCheckInYet');
  String get missedCheckIn => _t('missedCheckIn');
  String get trustedContacts => _t('trustedContacts');
  String get noTrustedContact => _t('noTrustedContact');
  String get requiredForSafety => _t('requiredForSafety');
  String get safetyNetworkComplete => _t('safetyNetworkComplete');
  String get tapToManage => _t('tapToManage');
  String get confirmEmergency => _t('confirmEmergency');
  String get emergencyAlertText => _t('emergencyAlertText');
  String get yesSendSOS => _t('yesSendSOS');
  String get emergencyAlertSent => _t('emergencyAlertSent');
  String get checkInSuccess => _t('checkInSuccess');
  String get addContactFirst => _t('addContactFirst');
  String get accountSettings => _t('accountSettings');
  String get checkInReminders => _t('checkInReminders');
  String get reminders => _t('reminders');
  String get premiumBanner => _t('premiumBanner');

  // Contact Home
  String get monitoringDashboard => _t('monitoringDashboard');
  String get noEldersLinked => _t('noEldersLinked');
  String get noEldersDesc => _t('noEldersDesc');
  String get lastActive => _t('lastActive');
  String get weeklySafetyInsights => _t('weeklySafetyInsights');
  String get last7Days => _t('last7Days');
  String get safe => _t('safe');
  String get missed => _t('missed');
  String get days => _t('days');
  String get setAlertThreshold => _t('setAlertThreshold');
  String get alertMeIf => _t('alertMeIf');
  String get missesCheckIn => _t('missesCheckIn');

  // Settings
  String get profile => _t('profile');
  String get displayName => _t('displayName');
  String get enterName => _t('enterName');
  String get updateName => _t('updateName');
  String get changePassword => _t('changePassword');
  String get currentPassword => _t('currentPassword');
  String get enterCurrentPassword => _t('enterCurrentPassword');
  String get newPassword => _t('newPassword');
  String get atLeast6Chars => _t('atLeast6Chars');
  String get dangerZone => _t('dangerZone');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountWarning => _t('deleteAccountWarning');
  String get upgradeToP => _t('upgradeToP');
  String get unlockPremium => _t('unlockPremium');
  String get premiumSubbed => _t('premiumSubbed');
  String get view => _t('view');

  // SOS Active State
  String get sosAlertActive => _t('sosAlertActive');
  String get helpOnTheWay => _t('helpOnTheWay');
  String get imSafeNow => _t('imSafeNow');
  String get tapWhenSafe => _t('tapWhenSafe');
  String get areYouSafe => _t('areYouSafe');
  String get alertOverText => _t('alertOverText');
  String get yesSafe => _t('yesSafe');
  String get couldNotCancel => _t('couldNotCancel');

  // Background Safety Monitor
  String get monitorTitle => _t('monitorTitle');
  String get monitorOnSub => _t('monitorOnSub');
  String get monitorOffSub => _t('monitorOffSub');
  String get monitorExplain => _t('monitorExplain');
  String get monitorPermNotifOk => _t('monitorPermNotifOk');
  String get monitorPermNotifMissing => _t('monitorPermNotifMissing');
  String get monitorPermBatteryOk => _t('monitorPermBatteryOk');
  String get monitorPermBatteryMissing => _t('monitorPermBatteryMissing');
  String get monitorNotifTitle => _t('monitorNotifTitle');
  String get monitorNotifBody => _t('monitorNotifBody');
  String get monitorChannelName => _t('monitorChannelName');
  String get monitorChannelDesc => _t('monitorChannelDesc');
  String get monitorNotifPermissionRequired =>
      _t('monitorNotifPermissionRequired');
  String get monitorCouldNotStart => _t('monitorCouldNotStart');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
