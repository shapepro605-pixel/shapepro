import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'ShapePro'**
  String get appName;

  /// No description provided for @splashSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua transformação começa aqui'**
  String get splashSubtitle;

  /// No description provided for @welcomeBack.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre na sua conta para continuar'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In pt, this message translates to:
  /// **'seu@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In pt, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// No description provided for @or.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get or;

  /// No description provided for @loginBiometric.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com Face ID / Digital'**
  String get loginBiometric;

  /// No description provided for @continueWithGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não tem conta? '**
  String get noAccount;

  /// No description provided for @registerFree.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta grátis'**
  String get registerFree;

  /// No description provided for @home.
  ///
  /// In pt, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @treino.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get treino;

  /// No description provided for @dieta.
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get dieta;

  /// No description provided for @resultado.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get resultado;

  /// No description provided for @hello.
  ///
  /// In pt, this message translates to:
  /// **'Olá,'**
  String get hello;

  /// No description provided for @atleta.
  ///
  /// In pt, this message translates to:
  /// **'Atleta'**
  String get atleta;

  /// No description provided for @yourImc.
  ///
  /// In pt, this message translates to:
  /// **'Seu IMC'**
  String get yourImc;

  /// No description provided for @peso.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get peso;

  /// No description provided for @altura.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get altura;

  /// No description provided for @weightEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Evolução do peso'**
  String get weightEvolution;

  /// No description provided for @dietaAtiva.
  ///
  /// In pt, this message translates to:
  /// **'Dieta ativa'**
  String get dietaAtiva;

  /// No description provided for @treinosSemana.
  ///
  /// In pt, this message translates to:
  /// **'Treinos da semana'**
  String get treinosSemana;

  /// No description provided for @calories.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get calories;

  /// No description provided for @proteins.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get proteins;

  /// No description provided for @carbs.
  ///
  /// In pt, this message translates to:
  /// **'Carbos'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras'**
  String get fats;

  /// No description provided for @myProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu perfil'**
  String get myProfile;

  /// No description provided for @subscription.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura'**
  String get subscription;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @deleteAccount.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Conta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Conta?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In pt, this message translates to:
  /// **'Isso apagará permanentemente todos os seus dados. Deseja continuar?'**
  String get deleteAccountDesc;

  /// No description provided for @help.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get help;

  /// No description provided for @aboutApp.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o App'**
  String get aboutApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logout;

  /// No description provided for @profileIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Perfil incompleto'**
  String get profileIncomplete;

  /// No description provided for @profileIncompleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Complete seus dados para uma dieta e treino precisos.'**
  String get profileIncompleteDesc;

  /// No description provided for @completeProfile.
  ///
  /// In pt, this message translates to:
  /// **'Completar'**
  String get completeProfile;

  /// No description provided for @editProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @selectSex.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o sexo'**
  String get selectSex;

  /// No description provided for @step.
  ///
  /// In pt, this message translates to:
  /// **'Etapa {current} de {total}'**
  String step(int current, int total);

  /// No description provided for @createAccount.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua conta'**
  String get createAccount;

  /// No description provided for @startJourney.
  ///
  /// In pt, this message translates to:
  /// **'Comece sua jornada de transformação'**
  String get startJourney;

  /// No description provided for @fillAllFields.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos corretamente'**
  String get fillAllFields;

  /// No description provided for @fullName.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get fullName;

  /// No description provided for @yourName.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome'**
  String get yourName;

  /// No description provided for @aboutYou.
  ///
  /// In pt, this message translates to:
  /// **'Sobre você'**
  String get aboutYou;

  /// No description provided for @needData.
  ///
  /// In pt, this message translates to:
  /// **'Precisamos de alguns dados para personalizar seu plano'**
  String get needData;

  /// No description provided for @age.
  ///
  /// In pt, this message translates to:
  /// **'Idade'**
  String get age;

  /// No description provided for @years.
  ///
  /// In pt, this message translates to:
  /// **'anos'**
  String get years;

  /// No description provided for @biologicalSex.
  ///
  /// In pt, this message translates to:
  /// **'Sexo biológico'**
  String get biologicalSex;

  /// No description provided for @male.
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get male;

  /// No description provided for @female.
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get female;

  /// No description provided for @yourMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Suas medidas'**
  String get yourMeasures;

  /// No description provided for @measuresSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Isso nos ajuda a calcular suas necessidades nutricionais'**
  String get measuresSubtitle;

  /// No description provided for @currentWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get currentWeight;

  /// No description provided for @yourObjective.
  ///
  /// In pt, this message translates to:
  /// **'Seu objetivo'**
  String get yourObjective;

  /// No description provided for @objectiveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o que mais se encaixa no seu momento'**
  String get objectiveSubtitle;

  /// No description provided for @loseWeight.
  ///
  /// In pt, this message translates to:
  /// **'Perder gordura'**
  String get loseWeight;

  /// No description provided for @loseWeightDesc.
  ///
  /// In pt, this message translates to:
  /// **'Emagrecer mantendo massa muscular'**
  String get loseWeightDesc;

  /// No description provided for @maintainWeight.
  ///
  /// In pt, this message translates to:
  /// **'Manter peso'**
  String get maintainWeight;

  /// No description provided for @maintainWeightDesc.
  ///
  /// In pt, this message translates to:
  /// **'Melhorar composição corporal'**
  String get maintainWeightDesc;

  /// No description provided for @gainMass.
  ///
  /// In pt, this message translates to:
  /// **'Ganhar massa'**
  String get gainMass;

  /// No description provided for @gainMassDesc.
  ///
  /// In pt, this message translates to:
  /// **'Hipertrofia e ganho de peso'**
  String get gainMassDesc;

  /// No description provided for @activityLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de atividade física'**
  String get activityLevel;

  /// No description provided for @sedentary.
  ///
  /// In pt, this message translates to:
  /// **'Sedentário'**
  String get sedentary;

  /// No description provided for @sedentaryDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escritório/casa'**
  String get sedentaryDesc;

  /// No description provided for @light.
  ///
  /// In pt, this message translates to:
  /// **'Leve'**
  String get light;

  /// No description provided for @lightDesc.
  ///
  /// In pt, this message translates to:
  /// **'1-2x/semana'**
  String get lightDesc;

  /// No description provided for @moderate.
  ///
  /// In pt, this message translates to:
  /// **'Moderado'**
  String get moderate;

  /// No description provided for @moderateDesc.
  ///
  /// In pt, this message translates to:
  /// **'3-5x/semana'**
  String get moderateDesc;

  /// No description provided for @intense.
  ///
  /// In pt, this message translates to:
  /// **'Intenso'**
  String get intense;

  /// No description provided for @intenseDesc.
  ///
  /// In pt, this message translates to:
  /// **'6-7x/semana'**
  String get intenseDesc;

  /// No description provided for @veryIntense.
  ///
  /// In pt, this message translates to:
  /// **'Muito intenso'**
  String get veryIntense;

  /// No description provided for @veryIntenseDesc.
  ///
  /// In pt, this message translates to:
  /// **'2x/dia'**
  String get veryIntenseDesc;

  /// No description provided for @dietPace.
  ///
  /// In pt, this message translates to:
  /// **'Ritmo da Dieta (Agressividade)'**
  String get dietPace;

  /// No description provided for @healthyFlexible.
  ///
  /// In pt, this message translates to:
  /// **'Saudável & Flexível'**
  String get healthyFlexible;

  /// No description provided for @healthyFlexibleDesc.
  ///
  /// In pt, this message translates to:
  /// **'Perda/ganho lento sem restrições severas'**
  String get healthyFlexibleDesc;

  /// No description provided for @standardBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Padrão Balanceado'**
  String get standardBalanced;

  /// No description provided for @standardBalancedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Resultados visíveis com esforço moderado'**
  String get standardBalancedDesc;

  /// No description provided for @extremeFast.
  ///
  /// In pt, this message translates to:
  /// **'Extremo / Mudar Rápido'**
  String get extremeFast;

  /// No description provided for @extremeFastDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cutting pesado ou Super Bulking (Estilo Desafio)'**
  String get extremeFastDesc;

  /// No description provided for @continueBtn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueBtn;

  /// No description provided for @creatingAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criando conta...'**
  String get creatingAccount;

  /// No description provided for @createMyAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar minha conta'**
  String get createMyAccount;

  /// No description provided for @myEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Minha Evolução'**
  String get myEvolution;

  /// No description provided for @nextCheckin.
  ///
  /// In pt, this message translates to:
  /// **'Próximo Check-in'**
  String get nextCheckin;

  /// No description provided for @scansHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Scans'**
  String get scansHistory;

  /// No description provided for @daysRemainingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {days} dias para o seu próximo scanner corporal de comparação.'**
  String daysRemainingDesc(int days);

  /// No description provided for @timeToUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Hora de Atualizar!'**
  String get timeToUpdate;

  /// No description provided for @newScanNow.
  ///
  /// In pt, this message translates to:
  /// **'Faça um novo scanner agora para ver seus resultados!'**
  String get newScanNow;

  /// No description provided for @neck.
  ///
  /// In pt, this message translates to:
  /// **'Pescoço'**
  String get neck;

  /// No description provided for @shoulders.
  ///
  /// In pt, this message translates to:
  /// **'Ombros'**
  String get shoulders;

  /// No description provided for @chest.
  ///
  /// In pt, this message translates to:
  /// **'Peito'**
  String get chest;

  /// No description provided for @waist.
  ///
  /// In pt, this message translates to:
  /// **'Cintura'**
  String get waist;

  /// No description provided for @hips.
  ///
  /// In pt, this message translates to:
  /// **'Quadril'**
  String get hips;

  /// No description provided for @leftArm.
  ///
  /// In pt, this message translates to:
  /// **'Braço Esq.'**
  String get leftArm;

  /// No description provided for @rightArm.
  ///
  /// In pt, this message translates to:
  /// **'Braço Dir.'**
  String get rightArm;

  /// No description provided for @leftThigh.
  ///
  /// In pt, this message translates to:
  /// **'Coxa Esq.'**
  String get leftThigh;

  /// No description provided for @rightThigh.
  ///
  /// In pt, this message translates to:
  /// **'Coxa Dir.'**
  String get rightThigh;

  /// No description provided for @leftCalf.
  ///
  /// In pt, this message translates to:
  /// **'Panturrilha Esq.'**
  String get leftCalf;

  /// No description provided for @rightCalf.
  ///
  /// In pt, this message translates to:
  /// **'Panturrilha Dir.'**
  String get rightCalf;

  /// No description provided for @iaMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Medidas IA'**
  String get iaMeasures;

  /// No description provided for @days.
  ///
  /// In pt, this message translates to:
  /// **'DIAS'**
  String get days;

  /// No description provided for @remvovePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Remover foto atual'**
  String get remvovePhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil atualizada!'**
  String get photoUpdated;

  /// No description provided for @errorPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar foto.'**
  String get errorPhoto;

  /// No description provided for @session.
  ///
  /// In pt, this message translates to:
  /// **'Sessão'**
  String get session;

  /// No description provided for @frontType.
  ///
  /// In pt, this message translates to:
  /// **'FRENTE'**
  String get frontType;

  /// No description provided for @sideType.
  ///
  /// In pt, this message translates to:
  /// **'PERFIL'**
  String get sideType;

  /// No description provided for @backType.
  ///
  /// In pt, this message translates to:
  /// **'COSTAS'**
  String get backType;

  /// No description provided for @height.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get height;

  /// No description provided for @bmi.
  ///
  /// In pt, this message translates to:
  /// **'IMC'**
  String get bmi;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Foto?'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover esta foto do seu histórico? Esta ação não pode ser desfeita.'**
  String get deletePhotoDesc;

  /// No description provided for @photoRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Foto removida com sucesso!'**
  String get photoRemoved;

  /// No description provided for @errorDeleting.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir: {error}'**
  String errorDeleting(String error);

  /// No description provided for @generate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar'**
  String get generate;

  /// No description provided for @myDiet.
  ///
  /// In pt, this message translates to:
  /// **'Minha Dieta'**
  String get myDiet;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @adjustRoute.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar Rota'**
  String get adjustRoute;

  /// No description provided for @changeBeforeGenerate.
  ///
  /// In pt, this message translates to:
  /// **'Mude antes de gerar'**
  String get changeBeforeGenerate;

  /// No description provided for @dry.
  ///
  /// In pt, this message translates to:
  /// **'Secar'**
  String get dry;

  /// No description provided for @grow.
  ///
  /// In pt, this message translates to:
  /// **'Crescer'**
  String get grow;

  /// No description provided for @healthy.
  ///
  /// In pt, this message translates to:
  /// **'Saudável'**
  String get healthy;

  /// No description provided for @extreme.
  ///
  /// In pt, this message translates to:
  /// **'Extremo'**
  String get extreme;

  /// No description provided for @noActiveDiet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma dieta ativa'**
  String get noActiveDiet;

  /// No description provided for @generatePersonalizedDiet.
  ///
  /// In pt, this message translates to:
  /// **'Gere sua dieta personalizada baseada nos seus dados de perfil'**
  String get generatePersonalizedDiet;

  /// No description provided for @generateMyDiet.
  ///
  /// In pt, this message translates to:
  /// **'Gerar minha dieta'**
  String get generateMyDiet;

  /// No description provided for @dailySummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo Diário'**
  String get dailySummary;

  /// No description provided for @meals.
  ///
  /// In pt, this message translates to:
  /// **'Refeições'**
  String get meals;

  /// No description provided for @results.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get results;

  /// No description provided for @invalidWeight.
  ///
  /// In pt, this message translates to:
  /// **'Informe um peso válido'**
  String get invalidWeight;

  /// No description provided for @weightLogged.
  ///
  /// In pt, this message translates to:
  /// **'Peso {weight}kg registrado!'**
  String weightLogged(Object weight);

  /// No description provided for @completed.
  ///
  /// In pt, this message translates to:
  /// **'concluídos'**
  String get completed;

  /// No description provided for @generated.
  ///
  /// In pt, this message translates to:
  /// **'geradas'**
  String get generated;

  /// No description provided for @logWeight.
  ///
  /// In pt, this message translates to:
  /// **'Registrar peso'**
  String get logWeight;

  /// No description provided for @logWeightToTrack.
  ///
  /// In pt, this message translates to:
  /// **'Registre seu peso para acompanhar sua evolução'**
  String get logWeightToTrack;

  /// No description provided for @history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get history;

  /// No description provided for @imcClassification.
  ///
  /// In pt, this message translates to:
  /// **'Classificação IMC'**
  String get imcClassification;

  /// No description provided for @underweight.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo do peso'**
  String get underweight;

  /// No description provided for @normalWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso normal'**
  String get normalWeight;

  /// No description provided for @overweight.
  ///
  /// In pt, this message translates to:
  /// **'Sobrepeso'**
  String get overweight;

  /// No description provided for @obesity1.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade I'**
  String get obesity1;

  /// No description provided for @obesity2.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade II'**
  String get obesity2;

  /// No description provided for @obesity3.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade III'**
  String get obesity3;

  /// No description provided for @treinos.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get treinos;

  /// No description provided for @treinoNum.
  ///
  /// In pt, this message translates to:
  /// **'Treino {type}'**
  String treinoNum(Object type);

  /// No description provided for @treinoNotAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Treino não disponível'**
  String get treinoNotAvailable;

  /// No description provided for @exercises.
  ///
  /// In pt, this message translates to:
  /// **'exercícios'**
  String get exercises;

  /// No description provided for @startWorkout.
  ///
  /// In pt, this message translates to:
  /// **'COMEÇAR TREINO'**
  String get startWorkout;

  /// No description provided for @cancelWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Treino?'**
  String get cancelWorkout;

  /// No description provided for @progressLost.
  ///
  /// In pt, this message translates to:
  /// **'O progresso será perdido.'**
  String get progressLost;

  /// No description provided for @exit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get exit;

  /// No description provided for @rest.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get rest;

  /// No description provided for @skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get skip;

  /// No description provided for @seriesDone.
  ///
  /// In pt, this message translates to:
  /// **'Série Concluída'**
  String get seriesDone;

  /// No description provided for @finishWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Treino'**
  String get finishWorkout;

  /// No description provided for @workoutFinished.
  ///
  /// In pt, this message translates to:
  /// **'🎉 Treino Finalizado! Você é incrível! +1 na conta!'**
  String get workoutFinished;

  /// No description provided for @executionTime.
  ///
  /// In pt, this message translates to:
  /// **'TEMPO DE EXECUÇÃO'**
  String get executionTime;

  /// No description provided for @stop.
  ///
  /// In pt, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @skipBtn.
  ///
  /// In pt, this message translates to:
  /// **'PULAR'**
  String get skipBtn;

  /// No description provided for @start.
  ///
  /// In pt, this message translates to:
  /// **'INICIAR'**
  String get start;

  /// No description provided for @noExercisesFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum exercício encontrado'**
  String get noExercisesFound;

  /// No description provided for @exercise.
  ///
  /// In pt, this message translates to:
  /// **'Exercício'**
  String get exercise;

  /// No description provided for @series.
  ///
  /// In pt, this message translates to:
  /// **'{count} séries'**
  String series(Object count);

  /// No description provided for @reps.
  ///
  /// In pt, this message translates to:
  /// **'{count} reps'**
  String reps(Object count);

  /// No description provided for @premiumTitle.
  ///
  /// In pt, this message translates to:
  /// **'ShapePro Premium'**
  String get premiumTitle;

  /// No description provided for @restore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @unlockPro.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie o Pro'**
  String get unlockPro;

  /// No description provided for @premiumDesc.
  ///
  /// In pt, this message translates to:
  /// **'Dietas agressivas e treinos ultra avançados para os melhores resultados.'**
  String get premiumDesc;

  /// No description provided for @havePromoCode.
  ///
  /// In pt, this message translates to:
  /// **'Tem um Reference Code?'**
  String get havePromoCode;

  /// No description provided for @promoCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'CÓDIGO (ex: VIP100)'**
  String get promoCodeHint;

  /// No description provided for @insertCodeBefore.
  ///
  /// In pt, this message translates to:
  /// **'Insira o código antes de escolher seu plano.'**
  String get insertCodeBefore;

  /// No description provided for @termsOfUse.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get termsOfUse;

  /// No description provided for @privacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get privacy;

  /// No description provided for @accessDuration.
  ///
  /// In pt, this message translates to:
  /// **'Acesso por {count} {unit}'**
  String accessDuration(Object count, Object unit);

  /// No description provided for @month.
  ///
  /// In pt, this message translates to:
  /// **'mês'**
  String get month;

  /// No description provided for @months.
  ///
  /// In pt, this message translates to:
  /// **'meses'**
  String get months;

  /// No description provided for @bestValue.
  ///
  /// In pt, this message translates to:
  /// **'MELHOR VALOR'**
  String get bestValue;

  /// No description provided for @errorLoadingPlans.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar planos.'**
  String get errorLoadingPlans;

  /// No description provided for @confirmSubscription.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Assinatura?'**
  String get confirmSubscription;

  /// No description provided for @confirmPlanActivation.
  ///
  /// In pt, this message translates to:
  /// **'Deseja ativar o {planName}? (Ambiente Simulado)'**
  String confirmPlanActivation(Object planName);

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @congrats.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns!'**
  String get congrats;

  /// No description provided for @paymentError.
  ///
  /// In pt, this message translates to:
  /// **'Erro no pagamento'**
  String get paymentError;

  /// No description provided for @difficulty.
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade'**
  String get difficulty;

  /// No description provided for @beginner.
  ///
  /// In pt, this message translates to:
  /// **'Iniciante'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In pt, this message translates to:
  /// **'Intermediário'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get advanced;

  /// No description provided for @groceryBudget.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento de Mercado'**
  String get groceryBudget;

  /// No description provided for @economic.
  ///
  /// In pt, this message translates to:
  /// **'Econômico'**
  String get economic;

  /// No description provided for @premium.
  ///
  /// In pt, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @standard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get standard;

  /// No description provided for @championshipsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Campeonatos & Desafios'**
  String get championshipsTitle;

  /// No description provided for @daily.
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get monthly;

  /// No description provided for @phoneNumber.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In pt, this message translates to:
  /// **'(DDD) 99999-9999'**
  String get phoneHint;

  /// No description provided for @phoneRequired.
  ///
  /// In pt, this message translates to:
  /// **'Telefone obrigatório'**
  String get phoneRequired;

  /// No description provided for @verifyPhone.
  ///
  /// In pt, this message translates to:
  /// **'Verificar Telefone'**
  String get verifyPhone;

  /// No description provided for @verifySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 6 dígitos para {phone}'**
  String verifySubtitle(String phone);

  /// No description provided for @codeHint.
  ///
  /// In pt, this message translates to:
  /// **'000000'**
  String get codeHint;

  /// No description provided for @verifyBtn.
  ///
  /// In pt, this message translates to:
  /// **'Verificar Código'**
  String get verifyBtn;

  /// No description provided for @resendCode.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar Código'**
  String get resendCode;

  /// No description provided for @invalidCode.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido'**
  String get invalidCode;

  /// No description provided for @lockedTrial.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo Bloqueado'**
  String get lockedTrial;

  /// No description provided for @upgradeToUnlock.
  ///
  /// In pt, this message translates to:
  /// **'Assine o Premium para desbloquear todas as refeições e treinos.'**
  String get upgradeToUnlock;

  /// No description provided for @medicalDisclaimerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Médico Importante'**
  String get medicalDisclaimerTitle;

  /// No description provided for @medicalDisclaimerDesc.
  ///
  /// In pt, this message translates to:
  /// **'Este aplicativo oferece orientações de fitness e nutrição apenas para fins informativos. Consulte sempre um médico antes de iniciar qualquer programa de exercícios ou dieta severa.'**
  String get medicalDisclaimerDesc;

  /// No description provided for @accept.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get accept;

  /// No description provided for @diet_generated.
  ///
  /// In pt, this message translates to:
  /// **'Sua dieta foi gerada com sucesso!'**
  String get diet_generated;

  /// No description provided for @bodyScanAI.
  ///
  /// In pt, this message translates to:
  /// **'Scanner Corporal'**
  String get bodyScanAI;

  /// No description provided for @trackBodyEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Registre sua evolução corporal'**
  String get trackBodyEvolution;

  /// No description provided for @open.
  ///
  /// In pt, this message translates to:
  /// **'ABRIR'**
  String get open;

  /// No description provided for @evolutionAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise de Evolução'**
  String get evolutionAnalysis;

  /// No description provided for @selectPoseType.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o tipo de foto que deseja tirar hoje.'**
  String get selectPoseType;

  /// No description provided for @front.
  ///
  /// In pt, this message translates to:
  /// **'Frente'**
  String get front;

  /// No description provided for @side.
  ///
  /// In pt, this message translates to:
  /// **'Lado'**
  String get side;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get back;

  /// No description provided for @sendPhoto.
  ///
  /// In pt, this message translates to:
  /// **'ENVIAR FOTO'**
  String get sendPhoto;

  /// No description provided for @photoSentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Foto enviada com sucesso! Seu progresso está sendo rastreado.'**
  String get photoSentSuccess;

  /// No description provided for @takeAnother.
  ///
  /// In pt, this message translates to:
  /// **'TIRAR OUTRA'**
  String get takeAnother;

  /// No description provided for @finish.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUIR'**
  String get finish;

  /// No description provided for @fullBodyNotDetected.
  ///
  /// In pt, this message translates to:
  /// **'Corpo inteiro não detectado. Afaste-se.'**
  String get fullBodyNotDetected;

  /// No description provided for @centerYourBody.
  ///
  /// In pt, this message translates to:
  /// **'Centralize seu corpo'**
  String get centerYourBody;

  /// No description provided for @stayStraight.
  ///
  /// In pt, this message translates to:
  /// **'Fique reto (não incline os ombros)'**
  String get stayStraight;

  /// No description provided for @invalidDistance.
  ///
  /// In pt, this message translates to:
  /// **'Distância inadequada da câmera'**
  String get invalidDistance;

  /// No description provided for @poseFront.
  ///
  /// In pt, this message translates to:
  /// **'Posicione-se de frente'**
  String get poseFront;

  /// No description provided for @poseSide.
  ///
  /// In pt, this message translates to:
  /// **'Posicione-se de lado'**
  String get poseSide;

  /// No description provided for @poseBack.
  ///
  /// In pt, this message translates to:
  /// **'Fique de costas'**
  String get poseBack;

  /// No description provided for @startingCamera.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando câmera...'**
  String get startingCamera;

  /// No description provided for @noBodyDetected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum corpo detectado'**
  String get noBodyDetected;

  /// No description provided for @perfectCapture.
  ///
  /// In pt, this message translates to:
  /// **'PERFEITO! PODE TIRAR A FOTO'**
  String get perfectCapture;

  /// No description provided for @state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get state;

  /// No description provided for @city.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get city;

  /// No description provided for @reportPrice.
  ///
  /// In pt, this message translates to:
  /// **'Informar Preço'**
  String get reportPrice;

  /// No description provided for @howMuchDoesThisCost.
  ///
  /// In pt, this message translates to:
  /// **'Quanto custa este alimento na sua cidade?'**
  String get howMuchDoesThisCost;

  /// No description provided for @pricePlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 25.50'**
  String get pricePlaceholder;

  /// No description provided for @savePrice.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR PREÇO'**
  String get savePrice;

  /// No description provided for @registerWeightToSeeChart.
  ///
  /// In pt, this message translates to:
  /// **'Registre seu peso para ver o gráfico'**
  String get registerWeightToSeeChart;

  /// No description provided for @monthlyIncome.
  ///
  /// In pt, this message translates to:
  /// **'Renda Mensal ({currency})'**
  String monthlyIncome(Object currency);

  /// No description provided for @dietBudget.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento para Dieta ({currency})'**
  String dietBudget(Object currency);

  /// No description provided for @time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get time;

  /// No description provided for @newVersion.
  ///
  /// In pt, this message translates to:
  /// **'Nova Versão!'**
  String get newVersion;

  /// No description provided for @updateAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Uma atualização importante para o ShapePro já está disponível. Melhore sua experiência!'**
  String get updateAvailable;

  /// No description provided for @mandatoryUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Esta atualização é obrigatória para continuar usando o app.'**
  String get mandatoryUpdate;

  /// No description provided for @later.
  ///
  /// In pt, this message translates to:
  /// **'DEPOIS'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAR AGORA'**
  String get updateNow;

  /// No description provided for @notificationDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de notificação negada.'**
  String get notificationDenied;

  /// No description provided for @priceReported.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado! Preço registrado para ajudar a IA.'**
  String get priceReported;

  /// No description provided for @trainingCoordination.
  ///
  /// In pt, this message translates to:
  /// **'Treinos coordenados!'**
  String get trainingCoordination;

  /// No description provided for @chestTriceps.
  ///
  /// In pt, this message translates to:
  /// **'Peito e Tríceps'**
  String get chestTriceps;

  /// No description provided for @backBiceps.
  ///
  /// In pt, this message translates to:
  /// **'Costas e Bíceps'**
  String get backBiceps;

  /// No description provided for @legsGlutes.
  ///
  /// In pt, this message translates to:
  /// **'Pernas e Glúteos'**
  String get legsGlutes;

  /// No description provided for @shouldersAbs.
  ///
  /// In pt, this message translates to:
  /// **'Ombros e Abdômen'**
  String get shouldersAbs;

  /// No description provided for @fullBodyFunctional.
  ///
  /// In pt, this message translates to:
  /// **'Full Body / Funcional'**
  String get fullBodyFunctional;

  /// No description provided for @noChampionships.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum campeonato disponível'**
  String get noChampionships;

  /// No description provided for @joinedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Inscrito com sucesso!'**
  String get joinedSuccess;

  /// No description provided for @joinError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao entrar no campeonato'**
  String get joinError;

  /// No description provided for @participate.
  ///
  /// In pt, this message translates to:
  /// **'PARTICIPAR'**
  String get participate;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Minha foto de perfil'**
  String get changeProfilePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get takePhoto;

  /// No description provided for @chooseGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get chooseGallery;

  /// No description provided for @uploading.
  ///
  /// In pt, this message translates to:
  /// **'Enviando...'**
  String get uploading;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get saveChanges;

  /// No description provided for @personalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Pessoais'**
  String get personalInfo;

  /// No description provided for @locationAndFinance.
  ///
  /// In pt, this message translates to:
  /// **'Localização e Finanças'**
  String get locationAndFinance;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar perfil'**
  String get profileUpdateError;

  /// No description provided for @country.
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @selectCountry.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o país'**
  String get selectCountry;

  /// No description provided for @currency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get currency;

  /// No description provided for @incomeHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 3500.00'**
  String get incomeHint;

  /// No description provided for @budgetHint.
  ///
  /// In pt, this message translates to:
  /// **'Quanto pode gastar com a dieta?'**
  String get budgetHint;

  /// No description provided for @stateHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: SP ou New York'**
  String get stateHint;

  /// No description provided for @cityHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: São Paulo ou Miami'**
  String get cityHint;

  /// No description provided for @brazil.
  ///
  /// In pt, this message translates to:
  /// **'Brasil'**
  String get brazil;

  /// No description provided for @usa.
  ///
  /// In pt, this message translates to:
  /// **'EUA'**
  String get usa;

  /// No description provided for @canada.
  ///
  /// In pt, this message translates to:
  /// **'Canadá'**
  String get canada;

  /// No description provided for @uk.
  ///
  /// In pt, this message translates to:
  /// **'Reino Unido'**
  String get uk;

  /// No description provided for @privacyIntroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Introdução'**
  String get privacyIntroTitle;

  /// No description provided for @privacyIntroDesc.
  ///
  /// In pt, this message translates to:
  /// **'O ShapePro está comprometido em proteger sua privacidade. Esta política descreve como coletamos e usamos seus dados para fornecer planos de treino e dieta personalizados.'**
  String get privacyIntroDesc;

  /// No description provided for @privacyDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Coleta de Dados'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataDesc.
  ///
  /// In pt, this message translates to:
  /// **'Coletamos informações como e-mail, telefone, peso, altura, idade e nível de atividade. Esses dados são usados exclusivamente para o cálculo do seu plano e monitoramento de progresso.'**
  String get privacyDataDesc;

  /// No description provided for @privacyPaymentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assinaturas e Pagamentos'**
  String get privacyPaymentTitle;

  /// No description provided for @privacyPaymentDesc.
  ///
  /// In pt, this message translates to:
  /// **'As assinaturas são processadas através da Google Play Store. O cancelamento pode ser feito a qualquer momento nas configurações da sua conta Google.'**
  String get privacyPaymentDesc;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exclusão de Dados'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você pode solicitar a exclusão permanente de sua conta e todos os dados associados a qualquer momento através do menu Configurações no aplicativo.'**
  String get privacyDeleteDesc;

  /// No description provided for @privacyContactTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contato'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactDesc.
  ///
  /// In pt, this message translates to:
  /// **'Para dúvidas sobre privacidade, entre em contato: suporte@shapepro.com.br'**
  String get privacyContactDesc;

  /// No description provided for @version.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// No description provided for @lastUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Última atualização'**
  String get lastUpdate;

  /// No description provided for @approximateValues.
  ///
  /// In pt, this message translates to:
  /// **'* Valores aproximados de peso e medidas.'**
  String get approximateValues;

  /// No description provided for @locationAndFinanceSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Esses dados ajudam a IA a sugerir alimentos com melhor custo-benefício na sua região.'**
  String get locationAndFinanceSubtitle;

  /// No description provided for @mandatory.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get mandatory;

  /// No description provided for @ageHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 25'**
  String get ageHint;

  /// No description provided for @heightHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 175'**
  String get heightHint;

  /// No description provided for @weightHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 70.5'**
  String get weightHint;

  /// No description provided for @suggestedWorkouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos Sugeridos'**
  String get suggestedWorkouts;

  /// No description provided for @suggestedWorkoutsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Planejados especialmente para seu objetivo (IA).'**
  String get suggestedWorkoutsDesc;

  /// No description provided for @workoutNum.
  ///
  /// In pt, this message translates to:
  /// **'Treino {type}'**
  String workoutNum(Object type);

  /// No description provided for @healthProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de Saúde ShapePro'**
  String get healthProfile;

  /// No description provided for @bodyMeasurements.
  ///
  /// In pt, this message translates to:
  /// **'Medidas Corporais (IA)'**
  String get bodyMeasurements;

  /// No description provided for @rightForearm.
  ///
  /// In pt, this message translates to:
  /// **'Antebraço Dir.'**
  String get rightForearm;

  /// No description provided for @leftForearm.
  ///
  /// In pt, this message translates to:
  /// **'Antebraço Esq.'**
  String get leftForearm;

  /// No description provided for @healthIndicators.
  ///
  /// In pt, this message translates to:
  /// **'Indicadores de Saúde'**
  String get healthIndicators;

  /// No description provided for @waistHipRatio.
  ///
  /// In pt, this message translates to:
  /// **'Cintura/Quadril'**
  String get waistHipRatio;

  /// No description provided for @waistHeightRatio.
  ///
  /// In pt, this message translates to:
  /// **'Cintura/Altura'**
  String get waistHeightRatio;

  /// No description provided for @vShape.
  ///
  /// In pt, this message translates to:
  /// **'V-Shape'**
  String get vShape;

  /// No description provided for @recentManualMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Medidas Manuais Recentes'**
  String get recentManualMeasures;

  /// No description provided for @fatPercentage.
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get fatPercentage;

  /// No description provided for @photosAttached.
  ///
  /// In pt, this message translates to:
  /// **'{count} fotos anexadas'**
  String photosAttached(Object count);

  /// No description provided for @noScansPerformed.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum scan realizado'**
  String get noScansPerformed;

  /// No description provided for @scansWillAppearHere.
  ///
  /// In pt, this message translates to:
  /// **'Suas fotos e medidas aparecerão aqui.'**
  String get scansWillAppearHere;

  /// No description provided for @legalDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Legal ShapePro'**
  String get legalDisclaimer;

  /// No description provided for @informativePurposeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Finalidade Informativa'**
  String get informativePurposeTitle;

  /// No description provided for @informativePurposeDesc.
  ///
  /// In pt, this message translates to:
  /// **'As medidas corporais exibidas são ESTIMATIVAS geradas por algoritmos de IA. Estes valores não são exatos e devem ser usados apenas para monitoramento de tendências.'**
  String get informativePurposeDesc;

  /// No description provided for @notAMedicalDeviceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não é um Dispositivo Médico'**
  String get notAMedicalDeviceTitle;

  /// No description provided for @notAMedicalDeviceDesc.
  ///
  /// In pt, this message translates to:
  /// **'O ShapePro App não é um dispositivo médico e não fornece diagnósticos. Os resultados não substituem avaliações físicas profissionais.'**
  String get notAMedicalDeviceDesc;

  /// No description provided for @consultProfessionalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Consulte Profissionais'**
  String get consultProfessionalsTitle;

  /// No description provided for @consultProfessionalsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Consulte sempre seu médico ou nutricionista antes de iniciar novas dietas ou rotinas de exercícios intensos.'**
  String get consultProfessionalsDesc;

  /// No description provided for @understood.
  ///
  /// In pt, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @bodyScannerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Scanner Corporal'**
  String get bodyScannerTitle;

  /// No description provided for @howItWorks.
  ///
  /// In pt, this message translates to:
  /// **'Como Funciona o Scanner?'**
  String get howItWorks;

  /// No description provided for @scannerTutorialSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Siga as posições abaixo para a IA extrair suas medidas baseadas na sua foto.'**
  String get scannerTutorialSubtitle;

  /// No description provided for @frontDesc.
  ///
  /// In pt, this message translates to:
  /// **'Fique de frente, pés separados e braços abertos mostrando a cintura.'**
  String get frontDesc;

  /// No description provided for @sideDesc.
  ///
  /// In pt, this message translates to:
  /// **'Fique de lado, coluna reta, braços ao lado do corpo.'**
  String get sideDesc;

  /// No description provided for @backDesc.
  ///
  /// In pt, this message translates to:
  /// **'Fique de costas para a câmera, mesma postura da frente.'**
  String get backDesc;

  /// No description provided for @viewEvolutionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Ver Meu Histórico de Evolução'**
  String get viewEvolutionHistory;

  /// No description provided for @camera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get gallery;

  /// No description provided for @scannerReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório do Scanner'**
  String get scannerReport;

  /// No description provided for @chestEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Peito (Estimado)'**
  String get chestEstimated;

  /// No description provided for @waistEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Cintura (Estimada)'**
  String get waistEstimated;

  /// No description provided for @hipsEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Quadril (Estimado)'**
  String get hipsEstimated;

  /// No description provided for @estimatedIAValues.
  ///
  /// In pt, this message translates to:
  /// **'* Valores estimados via IA baseados na pose e altura.'**
  String get estimatedIAValues;

  /// No description provided for @uploadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro no upload: {error}'**
  String uploadError(Object error);

  /// No description provided for @fitnessActivity.
  ///
  /// In pt, this message translates to:
  /// **'Minha Atividade'**
  String get fitnessActivity;

  /// No description provided for @viewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get viewDetails;

  /// No description provided for @fitnessScore.
  ///
  /// In pt, this message translates to:
  /// **'Fitness Score'**
  String get fitnessScore;

  /// No description provided for @fitnessScoreGood.
  ///
  /// In pt, this message translates to:
  /// **'BOM'**
  String get fitnessScoreGood;

  /// No description provided for @steps.
  ///
  /// In pt, this message translates to:
  /// **'Passos'**
  String get steps;

  /// No description provided for @kcal.
  ///
  /// In pt, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @sono.
  ///
  /// In pt, this message translates to:
  /// **'Sono'**
  String get sono;

  /// No description provided for @weeklyProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso Semanal'**
  String get weeklyProgress;

  /// No description provided for @wearablesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Wearables'**
  String get wearablesTitle;

  /// No description provided for @syncing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando...'**
  String get syncing;

  /// No description provided for @connected.
  ///
  /// In pt, this message translates to:
  /// **'Conectado'**
  String get connected;

  /// No description provided for @lastSync.
  ///
  /// In pt, this message translates to:
  /// **'Última sync: {time}'**
  String lastSync(String time);

  /// No description provided for @detectedWorkouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos Detectados'**
  String get detectedWorkouts;

  /// No description provided for @noSmartwatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não tem um Smartwatch?'**
  String get noSmartwatchTitle;

  /// No description provided for @noSmartwatchDesc.
  ///
  /// In pt, this message translates to:
  /// **'Adicione seus passos e atividades manualmente.'**
  String get noSmartwatchDesc;

  /// No description provided for @addManually.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR MANUALMENTE'**
  String get addManually;

  /// No description provided for @manualEntry.
  ///
  /// In pt, this message translates to:
  /// **'Entrada Manual'**
  String get manualEntry;

  /// No description provided for @syncFailed.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização Falhou'**
  String get syncFailed;

  /// No description provided for @healthConnectDesc.
  ///
  /// In pt, this message translates to:
  /// **'Certifique-se de que o Health Connect está instalado e autorizado.'**
  String get healthConnectDesc;

  /// No description provided for @install.
  ///
  /// In pt, this message translates to:
  /// **'INSTALAR'**
  String get install;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @premiumWearablesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Conecte seus dispositivos e acompanhe seu progresso real-time. Disponível para usuários Premium.'**
  String get premiumWearablesDesc;

  /// No description provided for @unlockPremium.
  ///
  /// In pt, this message translates to:
  /// **'DESBLOQUEAR PREMIUM'**
  String get unlockPremium;

  /// No description provided for @bpm.
  ///
  /// In pt, this message translates to:
  /// **'BPM Médio'**
  String get bpm;

  /// No description provided for @distancia.
  ///
  /// In pt, this message translates to:
  /// **'Distância'**
  String get distancia;

  /// No description provided for @metaDiaria.
  ///
  /// In pt, this message translates to:
  /// **'Meta Diária'**
  String get metaDiaria;

  /// No description provided for @atividade.
  ///
  /// In pt, this message translates to:
  /// **'Atividade'**
  String get atividade;

  /// No description provided for @fastingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Jejum Intermitente'**
  String get fastingTitle;

  /// No description provided for @fastingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe suas janelas'**
  String get fastingDesc;

  /// No description provided for @wearablesBannerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Wearables & Saúde'**
  String get wearablesBannerTitle;

  /// No description provided for @wearablesBannerDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sincronize seu relógio'**
  String get wearablesBannerDesc;

  /// No description provided for @premiumFastingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cronômetro Premium'**
  String get premiumFastingTitle;

  /// No description provided for @premiumFastingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Seu período de teste acabou. Desbloqueie o Jejum Intermitente e todas as refeições da dieta com o ShapePro Premium.'**
  String get premiumFastingDesc;

  /// No description provided for @fastingStateFasting.
  ///
  /// In pt, this message translates to:
  /// **'JEJUM'**
  String get fastingStateFasting;

  /// No description provided for @fastingStateEating.
  ///
  /// In pt, this message translates to:
  /// **'ALIMENTAÇÃO'**
  String get fastingStateEating;

  /// No description provided for @fastingStateReady.
  ///
  /// In pt, this message translates to:
  /// **'PRONTO'**
  String get fastingStateReady;

  /// No description provided for @remaining.
  ///
  /// In pt, this message translates to:
  /// **'Restante: {time}'**
  String remaining(String time);

  /// No description provided for @startFasting.
  ///
  /// In pt, this message translates to:
  /// **'INICIAR JEJUM'**
  String get startFasting;

  /// No description provided for @breakFasting.
  ///
  /// In pt, this message translates to:
  /// **'QUEBRAR JEJUM'**
  String get breakFasting;

  /// No description provided for @finishWindow.
  ///
  /// In pt, this message translates to:
  /// **'FINALIZAR JANELA'**
  String get finishWindow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
