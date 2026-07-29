/// Which store this build is compiled for. Set at build time with
/// `--dart-define=PLAY_STORE_BUILD=true`; the default (no flag) is the
/// sideload/GitHub-APK build.
///
/// Gates the self-update check (see services/update_checker.dart): Play policy
/// restricts apps that fetch/install code outside Play's own mechanism, and
/// Play already updates the app itself.
const bool isPlayStoreBuild =
    bool.fromEnvironment('PLAY_STORE_BUILD', defaultValue: false);
