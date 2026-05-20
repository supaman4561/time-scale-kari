const { withAndroidManifest } = require('@expo/config-plugins');

module.exports = function withForegroundService(config) {
  return withAndroidManifest(config, (config) => {
    const app = config.modResults.manifest.application?.[0];
    if (!app) return config;
    if (!app.service) app.service = [];

    const serviceName = 'com.supersami.foregroundservice.ForegroundService';
    if (!app.service.some(s => s.$?.['android:name'] === serviceName)) {
      app.service.push({
        $: {
          'android:name': serviceName,
          'android:enabled': 'true',
          'android:exported': 'false',
          'android:foregroundServiceType': 'specialUse',
          'android:stopWithTask': 'true',
        },
        // Required for specialUse type on Android 14+ (API 34+)
        property: [{
          $: {
            'android:name': 'android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE',
            'android:value': 'timer',
          },
        }],
      });
    }
    return config;
  });
};
