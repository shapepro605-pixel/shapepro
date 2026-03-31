// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ShapePro';

  @override
  String get splashSubtitle => 'Your transformation starts here';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to your account to continue';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordMinLength => 'Minimum 6 characters';

  @override
  String get forgotPassword => 'Forgot my password';

  @override
  String get login => 'Login';

  @override
  String get or => 'or';

  @override
  String get loginBiometric => 'Login with Face ID / Fingerprint';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get registerFree => 'Create free account';

  @override
  String get home => 'Home';

  @override
  String get treino => 'Workout';

  @override
  String get dieta => 'Diet';

  @override
  String get resultado => 'Results';

  @override
  String get hello => 'Hello,';

  @override
  String get atleta => 'Athlete';

  @override
  String get yourImc => 'Your BMI';

  @override
  String get peso => 'Weight';

  @override
  String get altura => 'Height';

  @override
  String get weightEvolution => 'Weight evolution';

  @override
  String get activeDiet => 'Active diet';

  @override
  String get weeklyTraining => 'Weekly workouts';

  @override
  String get calories => 'Calories';

  @override
  String get proteins => 'Proteins';

  @override
  String get carbs => 'Carbs';

  @override
  String get fats => 'Fats';

  @override
  String get myProfile => 'My profile';

  @override
  String get subscription => 'Subscription';

  @override
  String get settings => 'Settings';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Logout';

  @override
  String get profileIncomplete => 'Incomplete Profile';

  @override
  String get profileIncompleteDesc =>
      'Complete your data for accurate diet and training.';

  @override
  String get completeProfile => 'Complete';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get selectSex => 'Please select sex';

  @override
  String step(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get createAccount => 'Create your account';

  @override
  String get startJourney => 'Start your transformation journey';

  @override
  String get fillAllFields => 'Fill all fields correctly';

  @override
  String get fullName => 'Full name';

  @override
  String get yourName => 'Your name';

  @override
  String get aboutYou => 'About you';

  @override
  String get needData => 'We need some data to customize your plan';

  @override
  String get age => 'Age';

  @override
  String get years => 'years';

  @override
  String get biologicalSex => 'Biological sex';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get yourMeasures => 'Your measures';

  @override
  String get measuresSubtitle =>
      'This helps us calculate your nutritional needs';

  @override
  String get currentWeight => 'Current weight';

  @override
  String get yourObjective => 'Your objective';

  @override
  String get objectiveSubtitle => 'Choose what best fits your moment';

  @override
  String get loseWeight => 'Lose fat';

  @override
  String get loseWeightDesc => 'Lose weight while maintaining muscle mass';

  @override
  String get maintainWeight => 'Maintain weight';

  @override
  String get maintainWeightDesc => 'Improve body composition';

  @override
  String get gainMass => 'Gain mass';

  @override
  String get gainMassDesc => 'Hypertrophy and weight gain';

  @override
  String get activityLevel => 'Physical activity level';

  @override
  String get sedentary => 'Sedentary';

  @override
  String get sedentaryDesc => 'Office/home';

  @override
  String get light => 'Light';

  @override
  String get lightDesc => '1-2x/week';

  @override
  String get moderate => 'Moderate';

  @override
  String get moderateDesc => '3-5x/week';

  @override
  String get intense => 'Intense';

  @override
  String get intenseDesc => '6-7x/week';

  @override
  String get veryIntense => 'Very intense';

  @override
  String get veryIntenseDesc => '2x/day';

  @override
  String get dietPace => 'Diet Pace (Aggressiveness)';

  @override
  String get healthyFlexible => 'Healthy & Flexible';

  @override
  String get healthyFlexibleDesc =>
      'Slow loss/gain without severe restrictions';

  @override
  String get standardBalanced => 'Standard Balanced';

  @override
  String get standardBalancedDesc => 'Visible results with moderate effort';

  @override
  String get extremeFast => 'Extreme / Fast Change';

  @override
  String get extremeFastDesc =>
      'Heavy cutting or Super Bulking (Challenge style)';

  @override
  String get continueBtn => 'Continue';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get myDiet => 'My Diet';

  @override
  String get generate => 'Generate';

  @override
  String get adjustRoute => 'Adjust Route';

  @override
  String get changeBeforeGenerate => 'Change before generating';

  @override
  String get dry => 'Dry';

  @override
  String get grow => 'Grow';

  @override
  String get healthy => 'Healthy';

  @override
  String get extreme => 'Extreme';

  @override
  String get noActiveDiet => 'No active diet';

  @override
  String get generatePersonalizedDiet =>
      'Generate your personalized diet based on your profile data';

  @override
  String get generateMyDiet => 'Generate my diet';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get meals => 'Meals';

  @override
  String get results => 'Result';

  @override
  String get invalidWeight => 'Enter a valid weight';

  @override
  String weightLogged(Object weight) {
    return 'Weight ${weight}kg logged!';
  }

  @override
  String get completed => 'completed';

  @override
  String get generated => 'generated';

  @override
  String get logWeight => 'Log weight';

  @override
  String get logWeightToTrack => 'Log your weight to track your evolution';

  @override
  String get history => 'History';

  @override
  String get imcClassification => 'BMI Classification';

  @override
  String get underweight => 'Underweight';

  @override
  String get normalWeight => 'Normal weight';

  @override
  String get overweight => 'Overweight';

  @override
  String get obesity1 => 'Obesity I';

  @override
  String get obesity2 => 'Obesity II';

  @override
  String get obesity3 => 'Obesity III';

  @override
  String get treinos => 'Workouts';

  @override
  String treinoNum(Object type) {
    return 'Workout $type';
  }

  @override
  String get treinoNotAvailable => 'Workout not available';

  @override
  String get exercises => 'exercises';

  @override
  String get startWorkout => 'START WORKOUT';

  @override
  String get cancelWorkout => 'Cancel Workout?';

  @override
  String get progressLost => 'Progress will be lost.';

  @override
  String get exit => 'Exit';

  @override
  String get rest => 'Rest';

  @override
  String get skip => 'Skip';

  @override
  String get seriesDone => 'Series Done';

  @override
  String get finishWorkout => 'Finish Workout';

  @override
  String get workoutFinished =>
      '🎉 Workout Finished! You are amazing! +1 on the count!';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get exercise => 'Exercise';

  @override
  String series(Object count) {
    return '$count series';
  }

  @override
  String reps(Object count) {
    return '$count reps';
  }

  @override
  String get premiumTitle => 'ShapePro Premium';

  @override
  String get restore => 'Restore';

  @override
  String get unlockPro => 'Unlock Pro';

  @override
  String get premiumDesc =>
      'Aggressive diets and ultra advanced workouts for best results.';

  @override
  String get havePromoCode => 'Have a Reference Code?';

  @override
  String get promoCodeHint => 'CODE (ex: VIP100)';

  @override
  String get insertCodeBefore => 'Insert the code before choosing your plan.';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacy => 'Privacy';

  @override
  String accessDuration(Object count, Object unit) {
    return 'Access for $count $unit';
  }

  @override
  String get month => 'month';

  @override
  String get months => 'months';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String get errorLoadingPlans => 'Error loading plans.';

  @override
  String get confirmSubscription => 'Confirm Subscription?';

  @override
  String confirmPlanActivation(Object planName) {
    return 'Do you want to activate $planName? (Simulated Environment)';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get congrats => 'Congratulations!';

  @override
  String get paymentError => 'Payment error';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get groceryBudget => 'Grocery Budget';

  @override
  String get economic => 'Economic';

  @override
  String get premium => 'Premium';

  @override
  String get standard => 'Standard';
}
