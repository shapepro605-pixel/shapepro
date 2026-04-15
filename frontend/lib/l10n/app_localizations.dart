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

  /// No description provided for @help.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get help;

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
  /// **'Peso atual'**
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

  /// No description provided for @myDiet.
  ///
  /// In pt, this message translates to:
  /// **'Minha Dieta'**
  String get myDiet;

  /// No description provided for @generate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar'**
  String get generate;

  /// No description provided for @adjustRoute.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste de Rota'**
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

  /// No description provided for @monthlyIncome.
  ///
  /// In pt, this message translates to:
  /// **'Renda Mensal (R\$)'**
  String get monthlyIncome;

  /// No description provided for @dietBudget.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento para Dieta (R\$)'**
  String get dietBudget;

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

  /// No description provided for @logWeightToChart.
  ///
  /// In pt, this message translates to:
  /// **'Registre seu peso para ver o gráfico'**
  String get logWeightToChart;

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
