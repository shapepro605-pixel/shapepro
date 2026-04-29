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
  String get dietaAtiva => 'Active diet';

  @override
  String get treinosSemana => 'Weekly workouts';

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
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountDesc =>
      'This will permanently delete all your data. Do you wish to continue?';

  @override
  String get help => 'Help';

  @override
  String get aboutApp => 'About App';

  @override
  String get privacyPolicy => 'Privacy Policy';

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
  String get currentWeight => 'Weight';

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
  String get myEvolution => 'My Evolution';

  @override
  String get nextCheckin => 'Next Check-in';

  @override
  String get scansHistory => 'Scans History';

  @override
  String daysRemainingDesc(int days) {
    return '$days days remaining for your next comparison scan.';
  }

  @override
  String get timeToUpdate => 'Time to Update!';

  @override
  String get newScanNow => 'Do a new scan now to see your results!';

  @override
  String get neck => 'Neck';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get chest => 'Chest';

  @override
  String get waist => 'Waist';

  @override
  String get hips => 'Hips';

  @override
  String get leftArm => 'Left Arm';

  @override
  String get rightArm => 'Right Arm';

  @override
  String get leftThigh => 'Left Thigh';

  @override
  String get rightThigh => 'Right Thigh';

  @override
  String get leftCalf => 'Left Calf';

  @override
  String get rightCalf => 'Right Calf';

  @override
  String get iaMeasures => 'AI Measures';

  @override
  String get days => 'DAYS';

  @override
  String get remvovePhoto => 'Remove current photo';

  @override
  String get photoUpdated => 'Profile photo updated!';

  @override
  String get errorPhoto => 'Error uploading photo.';

  @override
  String get session => 'Session';

  @override
  String get frontType => 'FRONT';

  @override
  String get sideType => 'SIDE';

  @override
  String get backType => 'BACK';

  @override
  String get height => 'Height';

  @override
  String get bmi => 'BMI';

  @override
  String get deletePhotoTitle => 'Delete Photo?';

  @override
  String get deletePhotoDesc =>
      'Do you want to remove this photo from your history? This action cannot be undone.';

  @override
  String get photoRemoved => 'Photo removed successfully!';

  @override
  String errorDeleting(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get generate => 'Generate';

  @override
  String get myDiet => 'My Diet';

  @override
  String get delete => 'Delete';

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
  String get executionTime => 'EXECUTION TIME';

  @override
  String get stop => 'STOP';

  @override
  String get skipBtn => 'SKIP';

  @override
  String get start => 'START';

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

  @override
  String get championshipsTitle => 'Championships & Challenges';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => '(555) 000-0000';

  @override
  String get phoneRequired => 'Phone number required';

  @override
  String get verifyPhone => 'Verify Phone';

  @override
  String verifySubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get codeHint => '000000';

  @override
  String get verifyBtn => 'Verify Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get lockedTrial => 'Locked Content';

  @override
  String get upgradeToUnlock =>
      'Subscribe to Premium to unlock all meals and workouts.';

  @override
  String get medicalDisclaimerTitle => 'Important Medical Disclaimer';

  @override
  String get medicalDisclaimerDesc =>
      'This application provides fitness and nutrition guidance for informational purposes only. Always consult a physician before starting any exercise program or severe diet.';

  @override
  String get accept => 'Accept';

  @override
  String get diet_generated => 'Your diet has been generated successfully!';

  @override
  String get bodyScanAI => 'Body Scan AI';

  @override
  String get trackBodyEvolution => 'Track your body evolution';

  @override
  String get open => 'OPEN';

  @override
  String get evolutionAnalysis => 'Evolution Analysis';

  @override
  String get selectPoseType =>
      'Select the type of photo you want to take today.';

  @override
  String get front => 'Front';

  @override
  String get side => 'Side';

  @override
  String get back => 'Back';

  @override
  String get sendPhoto => 'SEND PHOTO';

  @override
  String get photoSentSuccess =>
      'Photo sent successfully! Your progress is being tracked.';

  @override
  String get takeAnother => 'TAKE ANOTHER';

  @override
  String get finish => 'FINISH';

  @override
  String get fullBodyNotDetected => 'Full body not detected. Step back.';

  @override
  String get centerYourBody => 'Center your body';

  @override
  String get stayStraight => 'Stay straight (don\'t tilt shoulders)';

  @override
  String get invalidDistance => 'Inadequate distance from camera';

  @override
  String get poseFront => 'Stand facing the camera';

  @override
  String get poseSide => 'Stand sideways';

  @override
  String get poseBack => 'Stand with your back to the camera';

  @override
  String get startingCamera => 'Starting camera...';

  @override
  String get noBodyDetected => 'No body detected';

  @override
  String get perfectCapture => 'PERFECT! YOU CAN TAKE THE PHOTO';

  @override
  String get state => 'State';

  @override
  String get city => 'City';

  @override
  String get reportPrice => 'Report Price';

  @override
  String get howMuchDoesThisCost => 'How much does this cost in your city?';

  @override
  String get pricePlaceholder => 'Ex: 25.50';

  @override
  String get savePrice => 'SAVE PRICE';

  @override
  String get registerWeightToSeeChart => 'Log your weight to see the chart';

  @override
  String monthlyIncome(Object currency) {
    return 'Monthly Income ($currency)';
  }

  @override
  String dietBudget(Object currency) {
    return 'Monthly Diet Budget ($currency)';
  }

  @override
  String get time => 'Time';

  @override
  String get newVersion => 'New Version!';

  @override
  String get updateAvailable =>
      'An important update for ShapePro is available. Improve your experience!';

  @override
  String get mandatoryUpdate =>
      'This update is required to continue using the app.';

  @override
  String get later => 'LATER';

  @override
  String get updateNow => 'UPDATE NOW';

  @override
  String get notificationDenied => 'Notification permission denied.';

  @override
  String get priceReported => 'Thank you! Price registered to help the AI.';

  @override
  String get trainingCoordination => 'Coordinated workouts!';

  @override
  String get chestTriceps => 'Chest & Triceps';

  @override
  String get backBiceps => 'Back & Biceps';

  @override
  String get legsGlutes => 'Legs & Glutes';

  @override
  String get shouldersAbs => 'Shoulders & Abs';

  @override
  String get fullBodyFunctional => 'Full Body / Functional';

  @override
  String get noChampionships => 'No championships available';

  @override
  String get joinedSuccess => 'Successfully joined!';

  @override
  String get joinError => 'Error joining championship';

  @override
  String get participate => 'JOIN';

  @override
  String get changeProfilePhoto => 'My profile photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseGallery => 'Choose from gallery';

  @override
  String get uploading => 'Uploading...';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get locationAndFinance => 'Location & Finance';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully!';

  @override
  String get profileUpdateError => 'Error updating profile';

  @override
  String get country => 'Country';

  @override
  String get selectCountry => 'Select country';

  @override
  String get currency => 'Currency';

  @override
  String get incomeHint => 'Ex: 3500.00';

  @override
  String get budgetHint => 'How much can you spend on diet?';

  @override
  String get stateHint => 'Ex: NY or Florida';

  @override
  String get cityHint => 'Ex: New York or Miami';

  @override
  String get brazil => 'Brazil';

  @override
  String get usa => 'USA';

  @override
  String get canada => 'Canada';

  @override
  String get uk => 'United Kingdom';

  @override
  String get privacyIntroTitle => 'Introduction';

  @override
  String get privacyIntroDesc =>
      'ShapePro is committed to protecting your privacy. This policy describes how we collect and use your data to provide personalized workout and diet plans.';

  @override
  String get privacyDataTitle => 'Data Collection';

  @override
  String get privacyDataDesc =>
      'We collect information such as email, phone, weight, height, age, and activity level. This data is used exclusively for calculating your plan and tracking progress.';

  @override
  String get privacyPaymentTitle => 'Subscriptions & Payments';

  @override
  String get privacyPaymentDesc =>
      'Subscriptions are processed through the Google Play Store. Cancellation can be made at any time in your Google account settings.';

  @override
  String get privacyDeleteTitle => 'Data Deletion';

  @override
  String get privacyDeleteDesc =>
      'You can request the permanent deletion of your account and all associated data at any time through the Settings menu in the application.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContactDesc =>
      'For questions about privacy, contact: support@shapepro.app';

  @override
  String get version => 'Version';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get approximateValues =>
      '* Approximate weight and measurement values.';

  @override
  String get locationAndFinanceSubtitle =>
      'This data helps the AI suggest food with the best cost-benefit in your region.';

  @override
  String get mandatory => 'Required';

  @override
  String get ageHint => 'Ex: 25';

  @override
  String get heightHint => 'Ex: 175';

  @override
  String get weightHint => 'Ex: 70.5';

  @override
  String get suggestedWorkouts => 'Suggested Workouts';

  @override
  String get suggestedWorkoutsDesc =>
      'Planned specifically for your goal (AI).';

  @override
  String workoutNum(Object type) {
    return 'Workout $type';
  }

  @override
  String get healthProfile => 'ShapePro Health Profile';

  @override
  String get bodyMeasurements => 'Body Measurements (AI)';

  @override
  String get rightForearm => 'Right Forearm';

  @override
  String get leftForearm => 'Left Forearm';

  @override
  String get healthIndicators => 'Health Indicators';

  @override
  String get waistHipRatio => 'Waist/Hip Ratio';

  @override
  String get waistHeightRatio => 'Waist/Height Ratio';

  @override
  String get vShape => 'V-Shape';

  @override
  String get recentManualMeasures => 'Recent Manual Measures';

  @override
  String get fatPercentage => 'Fat %';

  @override
  String photosAttached(Object count) {
    return '$count photos attached';
  }

  @override
  String get noScansPerformed => 'No scans performed';

  @override
  String get scansWillAppearHere =>
      'Your photos and measurements will appear here.';

  @override
  String get legalDisclaimer => 'ShapePro Legal Disclaimer';

  @override
  String get informativePurposeTitle => 'Informative Purpose';

  @override
  String get informativePurposeDesc =>
      'Body measurements shown are ESTIMATES generated by AI algorithms. These values are not exact and should only be used for monitoring trends and personal motivation.';

  @override
  String get notAMedicalDeviceTitle => 'Not a Medical Device';

  @override
  String get notAMedicalDeviceDesc =>
      'ShapePro App is not a medical device and does not provide diagnoses. Results do not replace professional physical evaluations.';

  @override
  String get consultProfessionalsTitle => 'Consult Professionals';

  @override
  String get consultProfessionalsDesc =>
      'Always consult your doctor or nutritionist before starting new diets or intense exercise routines.';

  @override
  String get understood => 'Understood';

  @override
  String get bodyScannerTitle => 'Body Scanner';

  @override
  String get howItWorks => 'How it works?';

  @override
  String get scannerTutorialSubtitle =>
      'Follow the positions below for AI to extract your measurements based on your photo.';

  @override
  String get frontDesc =>
      'Stand facing the camera, feet apart and arms open showing your waist.';

  @override
  String get sideDesc => 'Stand sideways, straight back, arms at your side.';

  @override
  String get backDesc =>
      'Stand with your back to the camera, same posture as the front.';

  @override
  String get viewEvolutionHistory => 'View My Evolution History';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get scannerReport => 'Scanner Report';

  @override
  String get chestEstimated => 'Chest (Estimated)';

  @override
  String get waistEstimated => 'Waist (Estimated)';

  @override
  String get hipsEstimated => 'Hips (Estimated)';

  @override
  String get estimatedIAValues =>
      '* AI estimated values based on pose and height.';

  @override
  String uploadError(Object error) {
    return 'Upload error: $error';
  }

  @override
  String get fitnessActivity => 'My Activity';

  @override
  String get viewDetails => 'View details';

  @override
  String get fitnessScore => 'Fitness Score';

  @override
  String get fitnessScoreGood => 'GOOD';

  @override
  String get steps => 'Steps';

  @override
  String get kcal => 'kcal';

  @override
  String get sono => 'Sleep';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get wearablesTitle => 'Wearables';

  @override
  String get syncing => 'Syncing...';

  @override
  String get connected => 'Connected';

  @override
  String lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get detectedWorkouts => 'Detected Workouts';

  @override
  String get noSmartwatchTitle => 'Don\'t have a Smartwatch?';

  @override
  String get noSmartwatchDesc => 'Add your steps and activities manually.';

  @override
  String get addManually => 'ADD MANUALLY';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get healthConnectDesc =>
      'Ensure Health Connect is installed and authorized.';

  @override
  String get install => 'INSTALL';

  @override
  String get retry => 'RETRY';

  @override
  String get premiumWearablesDesc =>
      'Connect your devices and track your progress in real-time. Available for Premium users.';

  @override
  String get unlockPremium => 'UNLOCK PREMIUM';

  @override
  String get bpm => 'Average BPM';

  @override
  String get distancia => 'Distance';

  @override
  String get metaDiaria => 'Daily Goal';

  @override
  String get atividade => 'Activity';
}
