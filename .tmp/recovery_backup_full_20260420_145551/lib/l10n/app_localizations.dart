import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Gaseel Courier'**
  String get appTitle;

  /// Orders page title
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Statistics page title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get drivingLicense;

  /// No description provided for @nationalIdCard.
  ///
  /// In en, this message translates to:
  /// **'National ID Card'**
  String get nationalIdCard;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @insuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Insurance Number'**
  String get insuranceNumber;

  /// No description provided for @awaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Review'**
  String get awaitingReview;

  /// No description provided for @reviewDescription.
  ///
  /// In en, this message translates to:
  /// **'We are currently reviewing your documents. Your account will be activated once they are approved.'**
  String get reviewDescription;

  /// No description provided for @secondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'seconds remaining'**
  String get secondsRemaining;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Splash screen text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splash;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Username validation error
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Login loading message
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// Permission page title
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// Location permission title
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// Location permission description
  ///
  /// In en, this message translates to:
  /// **'This app needs location permission to track deliveries and provide accurate delivery services.'**
  String get locationPermissionDescription;

  /// Grant permission button
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// Open settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Permission denied status
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permissionDenied;

  /// Permission denied message
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for this app to function properly. Please grant permission in settings.'**
  String get permissionDeniedMessage;

  /// Permission permanently denied title
  ///
  /// In en, this message translates to:
  /// **'Permission Permanently Denied'**
  String get permissionPermanentlyDenied;

  /// Permission permanently denied message
  ///
  /// In en, this message translates to:
  /// **'Location permission has been permanently denied. Please enable it in your device settings to use this app.'**
  String get permissionPermanentlyDeniedMessage;

  /// Requesting permission loading message
  ///
  /// In en, this message translates to:
  /// **'Requesting Permission...'**
  String get requestingPermission;

  /// Location unavailable title
  ///
  /// In en, this message translates to:
  /// **'Location Unavailable'**
  String get locationUnavailable;

  /// Location unavailable message
  ///
  /// In en, this message translates to:
  /// **'Unable to access location services. You can continue in demo mode.'**
  String get locationUnavailableMessage;

  /// Continue in demo mode button
  ///
  /// In en, this message translates to:
  /// **'Continue (Demo)'**
  String get continueDemo;

  /// Today date filter
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Upcoming tab label
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// Completed status and statistic label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// In progress status and statistic label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Pickup order type
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Dropoff order type
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get dropoff;

  /// Search orders placeholder
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get searchOrders;

  /// No orders message
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrders;

  /// No orders found message
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// Order details page title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// Order information section
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// Order ID label
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// Order type label
  ///
  /// In en, this message translates to:
  /// **'Order type'**
  String get orderType;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Scheduled date time label
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledDateTime;

  /// Location section
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Area label
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// District label
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// Coordinates label
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// Customer information section
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// Customer name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerName;

  /// Customer phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerPhone;

  /// Notes label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Home photos section
  ///
  /// In en, this message translates to:
  /// **'Home Photos'**
  String get homePhotos;

  /// Order not found message
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Required field validation error
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Invalid login credentials error
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidLogin;

  /// Enable location title
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationTitle;

  /// Enable location description
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to continue'**
  String get enableLocationDesc;

  /// Enable location button
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// Company name
  ///
  /// In en, this message translates to:
  /// **'Gaseel Express'**
  String get companyName;

  /// Login page subtitle
  ///
  /// In en, this message translates to:
  /// **'Login - Driver App'**
  String get loginSubtitle;

  /// Copyright footer text
  ///
  /// In en, this message translates to:
  /// **'© 2024 Gaseel Express. All rights reserved.'**
  String get copyright;

  /// Onboarding profile step title
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get onboardingProfileTitle;

  /// Onboarding profile step description
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile information to continue.'**
  String get onboardingProfileDesc;

  /// Profile placeholder text
  ///
  /// In en, this message translates to:
  /// **'Profile fields will be added here.'**
  String get onboardingProfilePlaceholder;

  /// Complete profile button
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// Permissions page title
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get permissionsTitle;

  /// Permissions page description
  ///
  /// In en, this message translates to:
  /// **'We need these permissions to provide you with the best delivery experience.'**
  String get permissionsDescription;

  /// Location permission name
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationPermissionName;

  /// Location permission description
  ///
  /// In en, this message translates to:
  /// **'Track your location for accurate delivery tracking'**
  String get locationPermissionDesc;

  /// Camera permission name
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraPermissionName;

  /// Camera permission description
  ///
  /// In en, this message translates to:
  /// **'Take photos of deliveries and documents'**
  String get cameraPermissionDesc;

  /// Contacts permission name
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsPermissionName;

  /// Contacts permission description
  ///
  /// In en, this message translates to:
  /// **'Quick contact with customers'**
  String get contactsPermissionDesc;

  /// Notifications permission name
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPermissionName;

  /// Notifications permission description
  ///
  /// In en, this message translates to:
  /// **'Receive order updates and important alerts'**
  String get notificationsPermissionDesc;

  /// Permission granted status
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// Permission not requested status
  ///
  /// In en, this message translates to:
  /// **'Not requested'**
  String get permissionNotRequested;

  /// Allow all permissions and continue button
  ///
  /// In en, this message translates to:
  /// **'Allow & Continue'**
  String get allowAndContinue;

  /// Message when some permissions are denied
  ///
  /// In en, this message translates to:
  /// **'Some permissions were denied. Please enable them in settings.'**
  String get somePermissionsDenied;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name validation error
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// Mobile number validation error
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// Invalid phone number format error
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// National ID field label
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// Profile photo label
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// Profile photo validation error
  ///
  /// In en, this message translates to:
  /// **'Profile photo is required'**
  String get profilePhotoRequired;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Choose from gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Send verification code button
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// Sending code loading state
  ///
  /// In en, this message translates to:
  /// **'Sending Code...'**
  String get sendingCode;

  /// OTP page title
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// OTP sent message
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to {phone}'**
  String verificationCodeSent(String phone);

  /// OTP input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enterCode;

  /// Verify OTP button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Verifying OTP loading state
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// Invalid OTP error
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidCode;

  /// Phone verified status
  ///
  /// In en, this message translates to:
  /// **'Phone Verified'**
  String get phoneVerified;

  /// Resend code button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Verify phone modal title
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// OTP modal subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your number (Mock)'**
  String get enterCodeSent;

  /// Verify button in mock modal
  ///
  /// In en, this message translates to:
  /// **'Verify (Mock)'**
  String get verifyMock;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Success message after mock verification
  ///
  /// In en, this message translates to:
  /// **'Phone verified (Mock)'**
  String get phoneVerifiedMock;

  /// Verified button text
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Orders page title
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// Today orders statistic label
  ///
  /// In en, this message translates to:
  /// **'Today Orders'**
  String get todayOrders;

  /// Filter all orders
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter new orders
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filterNew;

  /// Filter active/in progress orders
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// Filter completed/done orders
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// Filter in progress orders
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// Filter completed orders
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// Reset filter button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Apply filter button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Filter by order type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterByType;

  /// Filter by distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterByDistance;

  /// Filter by date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterByDate;

  /// Filter by area
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get filterByArea;

  /// Tomorrow date filter
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Custom date filter
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Sort by distance option
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortDistance;

  /// Sort by time option
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sortTime;

  /// Sort by status option
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortStatus;

  /// Sort button label
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Sort by nearest option
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearest;

  /// Sort by fastest ETA option
  ///
  /// In en, this message translates to:
  /// **'Fastest ETA'**
  String get fastestEta;

  /// Sort by newest option
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Start order button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Drawer menu item for Orders page
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get drawerOrders;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Change language menu item
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get menuLanguage;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get menuLogout;

  /// No description provided for @drawerLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogoutTitle;

  /// No description provided for @drawerLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to logout?'**
  String get drawerLogoutMessage;

  /// No description provided for @drawerLogoutYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get drawerLogoutYes;

  /// No description provided for @drawerLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get drawerLogoutCancel;

  /// No description provided for @drawerStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get drawerStatusOnline;

  /// No description provided for @drawerStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get drawerStatusOffline;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Delivery order type
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Distance away format
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String kmAway(String distance);

  /// Time away format
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minAway(String minutes);

  /// Has hanger label
  ///
  /// In en, this message translates to:
  /// **'Has hanger?'**
  String get hasClothesAccount;

  /// Map placeholder text
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapPlaceholder;

  /// Navigate button label
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// Customer messages section title
  ///
  /// In en, this message translates to:
  /// **'Customer messages'**
  String get customerMessages;

  /// No messages text
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// End order button
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Select template dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select template'**
  String get selectTemplate;

  /// Send/submit button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Template message: On my way
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get templateOnWay;

  /// Template message: I have arrived
  ///
  /// In en, this message translates to:
  /// **'I have arrived'**
  String get templateArrived;

  /// Template message: Order delivered
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get templateDelivered;

  /// Template message: Running late
  ///
  /// In en, this message translates to:
  /// **'Running late'**
  String get templateDelayed;

  /// Map page title
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Location permission denied title
  ///
  /// In en, this message translates to:
  /// **'Location Permission Denied'**
  String get locationPermissionDenied;

  /// Location permission denied message
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to show your current location. Please grant permission in settings.'**
  String get locationPermissionDeniedMessage;

  /// Map fallback location message
  ///
  /// In en, this message translates to:
  /// **'Showing Riyadh, Saudi Arabia'**
  String get mapShowingFallback;

  /// Shown when order has no lat/lng
  ///
  /// In en, this message translates to:
  /// **'No coordinates available'**
  String get noCoordinatesAvailable;

  /// Map load error title
  ///
  /// In en, this message translates to:
  /// **'Map failed to load'**
  String get mapLoadErrorTitle;

  /// Map load error message
  ///
  /// In en, this message translates to:
  /// **'Please check your Google Maps API key, internet connection, and try again.'**
  String get mapLoadErrorMessage;

  /// Pickup photos section title
  ///
  /// In en, this message translates to:
  /// **'Pickup Photos'**
  String get pickupPhotosTitle;

  /// Pickup photos hint text
  ///
  /// In en, this message translates to:
  /// **'Take clear photos of the clothes before pickup.'**
  String get pickupPhotosHint;

  /// Add photos button
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// Empty state text when no pickup photos added
  ///
  /// In en, this message translates to:
  /// **'No pickup photos yet'**
  String get pickupPhotosEmptyState;

  /// Dialog title asking to add another photo
  ///
  /// In en, this message translates to:
  /// **'Add another?'**
  String get pickupPhotosAddAnotherTitle;

  /// Dialog message asking to add another photo
  ///
  /// In en, this message translates to:
  /// **'Do you want to take another photo?'**
  String get pickupPhotosAddAnotherMessage;

  /// Validation message when trying to confirm pickup without photos
  ///
  /// In en, this message translates to:
  /// **'Please add at least one pickup photo before confirming.'**
  String get pickupPhotosRequired;

  /// Camera permission denied message
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to take photos.'**
  String get cameraPermissionDenied;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Confirm pickup button label
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirmPickup;

  /// No description provided for @goToOnline.
  ///
  /// In en, this message translates to:
  /// **'Go To Online'**
  String get goToOnline;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @appealCentre.
  ///
  /// In en, this message translates to:
  /// **'Appeal Centre'**
  String get appealCentre;

  /// No description provided for @tutorialCentre.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Centre'**
  String get tutorialCentre;

  /// No description provided for @contactCs.
  ///
  /// In en, this message translates to:
  /// **'Contact CS Team'**
  String get contactCs;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetails;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @stepCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get stepCourier;

  /// No description provided for @stepClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get stepClient;

  /// No description provided for @stepLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get stepLaundry;

  /// No description provided for @stepPickupFromHome.
  ///
  /// In en, this message translates to:
  /// **'Pickup from home'**
  String get stepPickupFromHome;

  /// No description provided for @stepDeliverToLaundry.
  ///
  /// In en, this message translates to:
  /// **'Deliver to laundry'**
  String get stepDeliverToLaundry;

  /// No description provided for @yourEarnings.
  ///
  /// In en, this message translates to:
  /// **'Your Earnings'**
  String get yourEarnings;

  /// No description provided for @baseAmount.
  ///
  /// In en, this message translates to:
  /// **'Base amount'**
  String get baseAmount;

  /// No description provided for @bonusIfDeliveredWithin.
  ///
  /// In en, this message translates to:
  /// **'+5 SAR bonus if delivered within {minutes} minutes'**
  String bonusIfDeliveredWithin(Object minutes);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @orderTypeLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get orderTypeLaundry;

  /// No description provided for @orderTypeIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get orderTypeIron;

  /// No description provided for @orderTypeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get orderTypeBoth;

  /// No description provided for @orderTypeCarpet.
  ///
  /// In en, this message translates to:
  /// **'Carpet'**
  String get orderTypeCarpet;

  /// No description provided for @buildingPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Building photos'**
  String get buildingPhotosTitle;

  /// No description provided for @buildingPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Photos of the building or entrance.'**
  String get buildingPhotosHint;

  /// No description provided for @buildingPhotosEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No building photos yet'**
  String get buildingPhotosEmptyState;

  /// No description provided for @customerPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer photos'**
  String get customerPhotosTitle;

  /// No description provided for @customerPhotosEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No customer photos'**
  String get customerPhotosEmptyState;

  /// No description provided for @progressOnTheWayToClient.
  ///
  /// In en, this message translates to:
  /// **'On the way to Client'**
  String get progressOnTheWayToClient;

  /// No description provided for @progressArrivedAtClient.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Client'**
  String get progressArrivedAtClient;

  /// No description provided for @progressOnTheWayToLaundry.
  ///
  /// In en, this message translates to:
  /// **'On the way to Laundry'**
  String get progressOnTheWayToLaundry;

  /// No description provided for @progressDeliveredToLaundry.
  ///
  /// In en, this message translates to:
  /// **'Delivered to Laundry'**
  String get progressDeliveredToLaundry;

  /// Status message while matching courier to order
  ///
  /// In en, this message translates to:
  /// **'Searching for new order...'**
  String get searchingForNewOrder;

  /// Incoming order screen title
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get incomingOrderTitle;

  /// Heading when new order is matched
  ///
  /// In en, this message translates to:
  /// **'New order found!'**
  String get incomingOrderNewOrderFound;

  /// First stop for delivery order
  ///
  /// In en, this message translates to:
  /// **'1st: Laundry'**
  String get incomingOrderFirstStopLaundry;

  /// First stop for pickup order
  ///
  /// In en, this message translates to:
  /// **'1st: Customer'**
  String get incomingOrderFirstStopCustomer;

  /// Second stop for delivery order
  ///
  /// In en, this message translates to:
  /// **'2nd: Customer'**
  String get incomingOrderSecondStopCustomer;

  /// Second stop for pickup order
  ///
  /// In en, this message translates to:
  /// **'2nd: Laundry'**
  String get incomingOrderSecondStopLaundry;

  /// Stop type label for laundry
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get labelLaundry;

  /// Stop type label for customer home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get labelHome;

  /// ETA section label
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get estimatedArrival;

  /// Warning when rejecting order
  ///
  /// In en, this message translates to:
  /// **'Rejecting may affect your rating'**
  String get rejectRatingWarning;

  /// Confirm reject button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get confirmReject;

  /// Map expand fullscreen button tooltip
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get expandMap;

  /// Map recenter/reset button tooltip
  ///
  /// In en, this message translates to:
  /// **'Reset map'**
  String get resetMap;

  /// Close fullscreen map button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeMap;

  /// Toast when incoming order countdown reaches zero
  ///
  /// In en, this message translates to:
  /// **'Order expired'**
  String get orderExpired;

  /// Optional label for countdown timer
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get timeRemaining;

  /// Earnings card title
  ///
  /// In en, this message translates to:
  /// **'Your Earnings'**
  String get yourEarningsTitle;

  /// Base earnings with amount placeholder
  ///
  /// In en, this message translates to:
  /// **'Base amount: SAR {amount}'**
  String baseAmountLabel(String amount);

  /// Bonus condition with placeholders
  ///
  /// In en, this message translates to:
  /// **'+{bonus} SAR bonus if delivered within {minutes} minute'**
  String bonusLabel(String bonus, String minutes);

  /// Countdown timer label
  ///
  /// In en, this message translates to:
  /// **'Accept within'**
  String get acceptWithinLabel;

  /// Dialog title when order expires
  ///
  /// In en, this message translates to:
  /// **'Order expired'**
  String get orderExpiredTitle;

  /// Dialog body when order expires
  ///
  /// In en, this message translates to:
  /// **'This order is no longer available. You will be returned to the map to find a new order.'**
  String get orderExpiredBody;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Close button for modals/dialogs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Active trip page title
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get activeTripTitle;

  /// Order number display with label
  ///
  /// In en, this message translates to:
  /// **'Order Number #{number}'**
  String orderNumberLabel(String number);

  /// ETA in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String etaMinutes(Object minutes);

  /// ETA as time range (e.g. 3:00 PM – 3:30 PM)
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String etaTimeRange(String start, String end);

  /// Open in Google Maps
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// Call customer/laundry
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// Show more order details
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// Primary action for delivery - first stop
  ///
  /// In en, this message translates to:
  /// **'Arrived at Laundry'**
  String get arrivedAtLaundry;

  /// Primary action for pickup - first stop
  ///
  /// In en, this message translates to:
  /// **'Arrived at Customer'**
  String get arrivedAtCustomer;

  /// Support/help button
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Support drawer title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportDrawerTitle;

  /// Collapse map button tooltip
  ///
  /// In en, this message translates to:
  /// **'Collapse map'**
  String get collapseMap;

  /// Destination label on map
  ///
  /// In en, this message translates to:
  /// **'Next destination'**
  String get nextDestination;

  /// Building photos section in modal
  ///
  /// In en, this message translates to:
  /// **'Building photos'**
  String get buildingPhotos;

  /// Full address label
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get fullAddress;

  /// Complaint text field hint
  ///
  /// In en, this message translates to:
  /// **'Describe your issue...'**
  String get complaintHint;

  /// Complaint form title
  ///
  /// In en, this message translates to:
  /// **'Submit a complaint'**
  String get complaintTitle;

  /// Success message after complaint submit
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted successfully'**
  String get complaintSubmitted;

  /// Success message when arrived button pressed
  ///
  /// In en, this message translates to:
  /// **'Arrived at destination'**
  String get arrivedSuccess;

  /// Order status label when courier arrived at laundry
  ///
  /// In en, this message translates to:
  /// **'Arrived at laundry'**
  String get statusArrivedAtLaundry;

  /// Order status label when courier arrived at customer
  ///
  /// In en, this message translates to:
  /// **'Arrived at customer'**
  String get statusArrivedAtCustomer;

  /// Confirmation dialog for arriving at laundry
  ///
  /// In en, this message translates to:
  /// **'Confirm arrival to the laundry?'**
  String get confirmArrivalLaundryQ;

  /// Confirmation dialog for picking up the order
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup?'**
  String get confirmPickupQ;

  /// Confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Button text after confirming arrival at laundry
  ///
  /// In en, this message translates to:
  /// **'I have picked up the order'**
  String get pickedUpButton;

  /// Messages action button
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Customer notes section label
  ///
  /// In en, this message translates to:
  /// **'Customer Notes'**
  String get customerNotes;

  /// Subtitle shown in chat app bar
  ///
  /// In en, this message translates to:
  /// **'Customer Chat'**
  String get customerChatSubtitle;

  /// Chat input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Camera attachment tooltip
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachCamera;

  /// Gallery attachment tooltip
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get attachGallery;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get cannedSure;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get cannedOnMyWay;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'Arriving in a few minutes'**
  String get cannedArrivingSoon;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'Can you share the exact location?'**
  String get cannedShareLocation;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'Order picked up'**
  String get cannedOrderPickedUp;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'Can you send a photo of the place?'**
  String get cannedSendPhoto;

  /// Canned reply
  ///
  /// In en, this message translates to:
  /// **'I will leave the clothes at the door'**
  String get cannedLeaveAtDoor;

  /// Button to open full-screen chat
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// Delivery page title
  ///
  /// In en, this message translates to:
  /// **'Deliver the order to the customer'**
  String get deliverToCustomerTitle;

  /// Clothes hanger indicator label
  ///
  /// In en, this message translates to:
  /// **'Is there a clothes hanger?'**
  String get clothesRelationshipQ;

  /// Shown when no clothes hanger
  ///
  /// In en, this message translates to:
  /// **'Face-to-face delivery'**
  String get faceToFaceDelivery;

  /// Building info panel title
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingPanelTitle;

  /// Building number label
  ///
  /// In en, this message translates to:
  /// **'Building No'**
  String get buildingNo;

  /// Floor number label
  ///
  /// In en, this message translates to:
  /// **'Floor No'**
  String get floorNo;

  /// Apartment number label
  ///
  /// In en, this message translates to:
  /// **'Apartment No'**
  String get apartmentNo;

  /// Steps section header
  ///
  /// In en, this message translates to:
  /// **'Follow the steps'**
  String get followSteps;

  /// Step 1 title
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get step1;

  /// Step 2 title
  ///
  /// In en, this message translates to:
  /// **'Step 2'**
  String get step2;

  /// Step 3 optional title
  ///
  /// In en, this message translates to:
  /// **'Step 3 (Optional)'**
  String get step3Optional;

  /// Link when courier cannot reach customer
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the customer'**
  String get cantReachCustomer;

  /// Link to sample photos
  ///
  /// In en, this message translates to:
  /// **'Previous photo examples'**
  String get previousPhotoExamples;

  /// Sample photos dialog title
  ///
  /// In en, this message translates to:
  /// **'Sample photos'**
  String get samplePhotosTitle;

  /// Final delivery confirmation button
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredBtn;

  /// Warning when no building photo taken
  ///
  /// In en, this message translates to:
  /// **'Please take at least one building photo to complete delivery'**
  String get mustTakeBuildingPhotoWarning;

  /// Step 2 instruction text
  ///
  /// In en, this message translates to:
  /// **'Take proof photos of arriving at the building to confirm reaching the customer address'**
  String get step2Instruction;

  /// Step 3 instruction text
  ///
  /// In en, this message translates to:
  /// **'Take photos of the order'**
  String get step3Instruction;

  /// Progress tracker step 1 (semantics/tooltip only)
  ///
  /// In en, this message translates to:
  /// **'Before pickup'**
  String get stepBeforePickup;

  /// Progress tracker step 2 (semantics/tooltip only)
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get stepPickedUp;

  /// Progress tracker step 3 (semantics/tooltip only)
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// Pickup flow: confirm arrival at customer
  ///
  /// In en, this message translates to:
  /// **'Confirm arrival to the customer?'**
  String get confirmArrivalCustomerQ;

  /// Pickup flow: confirm pickup from customer
  ///
  /// In en, this message translates to:
  /// **'I have picked up from customer'**
  String get pickedUpFromCustomerBtn;

  /// Pickup flow: confirm delivery to laundry
  ///
  /// In en, this message translates to:
  /// **'Confirm handover to laundry?'**
  String get confirmHandoverToLaundryQ;

  /// Pickup flow: final button label
  ///
  /// In en, this message translates to:
  /// **'Delivered to laundry'**
  String get deliveredToLaundryBtn;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
