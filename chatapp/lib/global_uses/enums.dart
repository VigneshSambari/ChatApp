enum emailSignupResults {
  SignUpNotCompleted,
  SignUpCompleted,
  EmailAlreadyPresent,
  ProblemsSignIp
}

enum emailSignInResults {
  EmailNotVerified,
  SignInCompleted,
  EmailorPasswordInvalid,
  UnexpectedError
}

enum googleSignInResults {
  SignInCompleted,
  SignInNotCompleted,
  UnexpectedError,
  AlreadySignedIn,
}

enum statusMediaFormats {
  TextStatus,
  ImageStatus,
}

enum ConnectionStateName {
  Connect,
  Pending,
  Accept,
  Connected,
}

enum GetFieldForImportantDataLocalDatabase {
  UserEmail,
  Token,
  ProfileImagePath,
  ProfileImageUrl,
  About,
  WallPaper,
  MobileNumber,
  Notification,
  AccountCreationDate,
  AccountCreationTime,
}

enum MessageHolderType {
  Me,
  ConnectedUsers,
}

enum StatusMediaTypes {
  TextActivity,
  ImageActivity,
}

enum ConnectionStateType {
  ButtonNameWidget,
  ButtonBorderColor,
  ButtonOnlyName,
}

enum OtherConnectionStatus {
  Request_Pending,
  Invitation_Came,
  Invitation_Accepted,
  Request_Accepted,
}

enum ChatMessageTypes {
  None,
  Text,
  Image,
  Video,
  Document,
  Audio,
  Location,
}

enum ImageProviderCategory {
  FileImage,
  ExactAssetImage,
  NetworkImage,
}
