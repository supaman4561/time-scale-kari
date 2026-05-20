module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['@testing-library/jest-native/extend-expect'],
  moduleNameMapper: {
    '^expo-sqlite$': '<rootDir>/__mocks__/expo-sqlite.ts',
    '^expo-notifications$': '<rootDir>/__mocks__/expo-notifications.ts',
  },
  testPathIgnorePatterns: ['/node_modules/', '/android/', '/ios/'],
};
