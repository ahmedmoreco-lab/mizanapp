import 'app_localizations.dart';

extension MizanLocalizations on AppLocalizations {
  bool get isArabic => locale.languageCode == 'ar';

  String mizanText(String english, String arabic) =>
      isArabic ? arabic : english;

  String planText(String value) {
    if (!isArabic) return value;
    return _planTranslations[value] ?? value;
  }
}

const _planTranslations = <String, String>{
  'Protect your energy and complete one meaningful task':
      'حافظ على طاقتك وأنجز مهمة واحدة ذات معنى',
  'Finish the highest-impact work before the day gets busy':
      'أنجز العمل الأعلى أثراً قبل أن يزدحم اليوم',
  'Make steady progress on health and personal growth':
      'تقدم بثبات في صحتك ونموك الشخصي',
  'Drink water': 'اشرب الماء',
  'Take five calm breaths': 'خذ خمسة أنفاس هادئة',
  'Do gentle mobility': 'قم بحركات خفيفة',
  'Stretch and move': 'تمدد وتحرك',
  'Review today’s main goal': 'راجع هدف اليوم الرئيسي',
  'Complete the highest-impact work item': 'أنجز مهمة العمل الأعلى أثراً',
  'Start with the outcome that matters most today.':
      'ابدأ بالنتيجة الأكثر أهمية اليوم.',
  'Advance one business-development action': 'تقدم بخطوة في تطوير الأعمال',
  'Send the message, draft the offer, or make the decision.':
      'أرسل الرسالة أو اكتب العرض أو اتخذ القرار.',
  'Move a personal project forward': 'ادفع مشروعاً شخصياً إلى الأمام',
  'Choose one visible result you can finish today.':
      'اختر نتيجة واضحة يمكنك إنهاؤها اليوم.',
  'Complete a focused learning session': 'أكمل جلسة تعلم مركزة',
  'Read, practice, and capture one useful takeaway.':
      'اقرأ وتدرّب وسجّل فائدة واحدة.',
  'Complete today’s training session': 'أكمل تمرين اليوم',
  'Take a restorative walk': 'قم بمشية للاستشفاء',
  'Choose training or a restorative walk': 'اختر التمرين أو مشية للاستشفاء',
  'Train with intention, then recover and refuel.':
      'تمرّن بتركيز ثم استشفِ وتغذَّ جيداً.',
  'Keep the pace easy and support recovery.':
      'حافظ على وتيرة سهلة وادعم الاستشفاء.',
  'Decide after checking your energy this afternoon.':
      'قرر بعد تقييم طاقتك هذا المساء.',
  'Fuel a training day': 'غذِّ يوم التمرين',
  'Build a steady-energy plate': 'كوّن طبقاً يدعم طاقة مستقرة',
  'Keep protein high and include enough carbohydrate around training.':
      'حافظ على بروتين مرتفع وأضف كربوهيدرات كافية حول التمرين.',
  'Choose a simple balanced meal that avoids an afternoon energy crash.':
      'اختر وجبة بسيطة ومتوازنة تتجنب هبوط طاقة المساء.',
  'One to two palms of lean protein': 'حصة إلى حصتين من البروتين قليل الدهن',
  'One to two cupped hands': 'حصة إلى حصتين باليد',
  'One cupped hand': 'حصة واحدة باليد',
  'At least half the plate': 'نصف الطبق على الأقل',
  'One thumb-sized serving': 'حصة بحجم الإبهام',
  'Drink water and choose the simplest suitable option available.':
      'اشرب الماء واختر أبسط خيار مناسب متاح.',
  'Take a gentle 15-minute walk': 'قم بمشية خفيفة لمدة 15 دقيقة',
  'Use a free 20 minutes for reading or a short learning session':
      'استثمر 20 دقيقة فراغ في القراءة أو جلسة تعلم قصيرة',
  'Take an outdoor walk and leave the phone in your pocket':
      'اخرج للمشي واترك الهاتف في جيبك',
};
