import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'meditation_detail_page.dart';
import '../models/meditation_model.dart';

class MeditationsListPage extends StatefulWidget {
  const MeditationsListPage({super.key});

  @override
  State<MeditationsListPage> createState() => _MeditationsListPageState();
}

class _MeditationsListPageState extends State<MeditationsListPage>
    with SingleTickerProviderStateMixin {
  late List<MeditationModel> _meditations;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initMeditations();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimations = List.generate(_meditations.length, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(_meditations.length, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  void _initMeditations() {
    _meditations = [
      MeditationModel(
          id: '1',
          title: 'الصباح',
          fullText:
              'يا إلهي أنت أبي السماوي ومخلصي! بما أنك شئت أن تحفظني بنعمتك أثناء الليل الذي ولّى وحتى هذا الصباح الذي بدا, ساعدني على أن أستعمل كل هذا النهار في خدمتك, وأن لا أفكر أو أقول أو اعمل أي شيء إن لم يكن لإرضائك ولا طاعة إرادتك المقدسة لكي تؤول جميع أعمالي لمجد اسمك ولخلاص إخوتي. وكما أنك تشع بشمسك على هذا العالم أنر أيضاً عقلي بنور روحك لكي أسير في سبيل البر.\nيا إلهي أنت أبي السماوي ومخلصي! بما أنك شئت أن تحفظني بنعمتك أثناء الليل الذي ولّى وحتى هذا الصباح الذي بدا, ساعدني على أن أستعمل كل هذا النهار في خدمتك, وأن لا أفكر أو أقول أو اعمل أي شيء إن لم يكن لإرضائك ولا طاعة إرادتك المقدسة لكي تؤول جميع أعمالي لمجد اسمك ولخلاص إخوتي. وكما أنك تشع بشمسك على هذا العالم أنر أيضاً عقلي بنور روحك لكي أسير في سبيل البر.\nوبما أنه من العبث البدء في أمر إن لم نثابر عليه, أتضرع إليك يا الله بأن تقودني وترشدني ليس فقط في هذا اليوم بل في كل أيام حياتي. أكثر فيّ أيضاً هبات نعمتك لكي أتقدم من يوم إلى آخر حتى أصل إلى الشركة الكاملة مع ابنك الحبيب يسوع المسيح الذي هو النور الحقيقي لأنفسنا. وأتوسل إليك يا إلهي لكي أنال منك كل هذه الخيرات بأن تنسى جميع أخطائي وأن تغفر لي ذنوبي حسب رحمتك اللامتناهية كما وعدت بذلك جميع الذين يدعونك بقلب صادق بواسطة يسوع المسيح مخلصنا, آمين.'),
      MeditationModel(
        id: '2',
        title: 'المساء',
        fullText:
            'يا ربي وإلهي بما أنك قد عملت الليل لراحة الإنسان أتوسل إليك بأن تعطي جسدي راحة في هذا الليل وأن تعمل على أن ترتفع نفسي إليك وأن يكون قلبي دائماً مملوءً بمحبتك. علمني يا الله بأن أودعك جميع مخاوفي وأن أتذكر رأفتك بدون انقطاع لكي تستطيع نفسي بأن تحصل على راحتها الروحية. ولا تدع نومي أن يكون زائداً عن اللازم بل أن يساعدني على استرجاع قواي لكي أصبح أكثر أهلاً لخدمتك. لتكن إرادتك بأن تحفظني نقياً في جسدي وروحي وأن تقيني من جميع التجارب والأخطار لكي يؤول نومي أيضا إلى مجد اسمك.\nوبما أن هذا النهار لم يمض بدون أن أكون قد أخطأت إليك بطرق عديدة, أتضرح إليك يا الله أنا الخاطىء بأن تدفن كل خطاياي حسب رحمتك كما أنك تخفي كل شيء تحت ظلام الليل. أرفع صلاتي بواسطة يسوع المسيح مخلصي. آمين.',
      ),
      MeditationModel(
        id: '3',
        title: 'الطلبة',
        fullText:
            'يا ربي أن منبع كل حكمة وكل معرفة! بما انه سرك فأعطيتني في أيام حداثتي التعليم الذي يساعدني على العيش بقداسة وباستقامة, أنر عقلي أيضاً لكي أفهم كطل ما سأتلقنه, قوِّ ذاكرتي لكي أستطيع حفظ ما تعلمته, وقد قلبي لكي أسعى بأن أتقدم كثيراً في دراستي وهكذا لا أخسر الفرصة التي تمنحني إياها هذا اليوم من أجل ثقافتي. امنحني يا إلهي روحك, روح الذكاء والحق والتمييز والحكمة لأستفيد جيداً من كل ما أتعلمه ولا أجعل عبثاً الجهد المبذول لتعليمي.\nساعدني يا رب أن أجعل كل دروسي ومطالعاتي تصل إليك غايتها الحقيقية ألا وهي معرفتك بواسطة يسوع المسيح لبنك, وهكذا أتأكد من حصولي على نعمتك فأخدمك بإخلاص. وبما أنك تعدنا بأن تنير بحكمتك الصغار والمتواضعين – إذ انك ترفض المتكبرين فيتوهون في أفكارهم الباطلة – أتوسل إليك يا إلهي بأن تخلق فيَّ التواضع الحقيقي الذي يجعلني وديعاً ومطيعاً لك أولاً وكذلك لكل الذين جعلتهم لتعليمي. وساعد قلبي على أن يرفض كل رغبة شريرة وأن يطلب دائماًُ أن تكون غايتي الوحيدة الآن هي أن أهيء نفسي لخدمتك يا إلهي في الدعوة التي سيسرك بأن تدعوني إليها. استجب لي إكراماً لسيدنا يسوع المسيح. آمين.',
      ),
      MeditationModel(
        id: '4',
        title: 'قبل الطعام',
        fullText:
            'يا ربنا أنت المنبع الدائم لجميع الخيرات, إليك نتوسل بأن تبارك وتقدس لنا هذا الطعام الذي نستلمه من وجودك لكي نستعمل مأكلنا بتعقل كما انك تتوقع ذلك منا. ساعدنا لنعترف بك دوماً كالآب السماوي صانع كل الخيرات وأن نطلب قبل كل شيء الغذاء الروحي الكائن في كلمته المقدسة لكيي تتغذى أرواحنا أبدياً بيسوع المسيح مخلصنا. آمين.',
      ),
      MeditationModel(
        id: '5',
        title: 'بعد الطعام',
        fullText:
            'نشكرك يا أبانا السماوي من أجل كل الخيرات التي أغدقتها علينا بدون انقطاع حسب رحمتك اللامتناهية. ليتبارك اسمك لأنك تعتني بأجسادنا باعطائها كل ما يلزم ولحفظها في هذه الحياة, وخاصة لأن سرك بأن تجدد حياتنا في رجاء حياة أفضل التي أعلنتها لنا في إنجيلك المقدس.\nنتضرع إليك يا إلهنا بأن لا تسمح لنا بأن ننشغل بأمور ومخاوف هذا العالم الفاني, بل ساعدنا لكي ننظر إلى الأعلى رافعين أعيننا إلى السماء ومنتظرين دوما ربنا يسوع المسيح الذي سيأتي من السماء لفدائنا ولخلاصنا. آمين.',
      ),
      MeditationModel(
        id: '6',
        title: 'الاعتراف بالخطية',
        fullText:
            'ارحمني يا الله حسب رحمتك, حسب كثرة رأفتك امح معاصي. اغسلني كثيراً من إثمي ومن خطيتي طهرني. لأن عارف بمعاصي, وخطيتي أمامي دائماً. إليك وحدك أخطأت, والشر قدام عينيك صنعت لكي تتبرر في أقوالك وتزكو في قضائك. هاءنذا بالإثم صورت, وبالخطية حبلت بي أمي.\nها قد سررت بالحق في الباطن, في السرير تعرفني حكمة. طهرني بالزوفا فأطهر, اغسلني فأبيض أكثر من الثلج. أسمعني سروراً وفرحاً وتبتهج عظاماً سحقتها. استر وجهك عن خطاياي وامحوا كل آثامي.\nقلباً نقياً اخلق في يا الله, وروحاً مستقيماً جدد في داخلي. لا تطرحني من قدام وجهك وروحك القدوس لا تنزعه مني. رد لي بهجة خلاصك وبروح منتدبة أعضدني, فأعلم الأثمة طرقك والخطاة إليك يرجعون.\nنجني من الدماء يا الله إله خلاصي, فيسبح لساني برك. يا رب افتح شفتي فيخبر فمي بتسبيحك. لأنك لا تسر ذبيحة وإلا فكنت أقدمها, بمحرقة لا ترضى. ذبائح الله هي روح منكسرة, والقلب المنكسر والمنسحق يا الله لا تحتقره!" آمين.',
      ),
      MeditationModel(
        id: '7',
        title: 'قانون الإيمان',
        fullText:
            'نؤمن بإله واحد آب ضابط الكل خالق السماء والأرض كل ما يرى وما لا يرى. وبرب واحد يسوع المسيح ابن الله الوحيد المولود من الآب قبل كل الدهور, إله من إله, نور من نور, إله حق من إله حق, مولود غير مخلوق مساو للآب في الجوهر الذي به كان كل شيء, الذي من أجلنا نحن البشر ومن أجل خلاصنا نزل من السماء وتجسد بالروح القدس ومن مريم العذراء وصار إنساناً, وصلب أيضاً عنا على عهد بيلاطس البنطي, تألم ومات وقام في اليوم الثالث كما في الكتب, وصعد إلى السماء وجلس عن يمين الآب, وسيأتي بمجد ليدين الأحياء والأموات الذي ليس لملكه انقضاء.\nوأومن بالروح القدس الرب المحيي, من الآب والابن, الذي هو مع الآب والابن يسجد له ويمجد, الناطق بالأنبياء.\nوأومن بكنيسة واحدة مقدسة جامعة ورسولية. واعترف بمعمودية واحدة لمغفرة الخطايا, وأترجى قيامة الموتى والحياة في الدهر الآتي, آمين.',
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: provider.backgroundColor,
            appBar: AppBar(
              backgroundColor: provider.cardColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4ADE80)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'صلوات قصيرة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
            ),
            body: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: _meditations.length,
              itemBuilder: (context, index) {
                final meditation = _meditations[index];

                return FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: SlideTransition(
                    position: _slideAnimations[index],
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: provider.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MeditationDetailPage(
                                meditation: meditation,
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            color: Color(0xFF4ADE80),
                            size: 28,
                          ),
                        ),
                        title: Text(
                          meditation.title,
                          style: GoogleFonts.cairo(
                            fontSize: 18 * provider.fontScale,
                            fontWeight: FontWeight.bold,
                            color: provider.textColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
