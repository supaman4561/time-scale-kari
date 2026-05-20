import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Text } from 'react-native';
import { COLORS } from '../theme';
import TodayScreen from '../screens/TodayScreen';
import CalendarScreen from '../screens/CalendarScreen';
import DayDetailScreen from '../screens/DayDetailScreen';
import SettingsScreen from '../screens/SettingsScreen';
import CategoryEditScreen from '../screens/CategoryEditScreen';

export type CalendarStackParamList = {
  CalendarHome: undefined;
  DayDetail: { date: string };
};

export type SettingsStackParamList = {
  SettingsHome: undefined;
  CategoryEdit: { categoryId?: number };
};

const Tab = createBottomTabNavigator();
const CalendarStack = createNativeStackNavigator<CalendarStackParamList>();
const SettingsStack = createNativeStackNavigator<SettingsStackParamList>();

function CalendarNavigator() {
  return (
    <CalendarStack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: COLORS.bg },
        headerTintColor: COLORS.text,
      }}
    >
      <CalendarStack.Screen name="CalendarHome" component={CalendarScreen} options={{ title: 'カレンダー' }} />
      <CalendarStack.Screen name="DayDetail" component={DayDetailScreen} options={{ title: '詳細' }} />
    </CalendarStack.Navigator>
  );
}

function SettingsNavigator() {
  return (
    <SettingsStack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: COLORS.bg },
        headerTintColor: COLORS.text,
      }}
    >
      <SettingsStack.Screen name="SettingsHome" component={SettingsScreen} options={{ title: '設定' }} />
      <SettingsStack.Screen name="CategoryEdit" component={CategoryEditScreen} options={{ title: 'カテゴリ編集' }} />
    </SettingsStack.Navigator>
  );
}

export default function AppNavigator() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          tabBarStyle: { backgroundColor: COLORS.surface, borderTopColor: COLORS.border },
          tabBarActiveTintColor: COLORS.accent,
          tabBarInactiveTintColor: COLORS.textMuted,
          headerStyle: { backgroundColor: COLORS.bg },
          headerTintColor: COLORS.text,
        }}
      >
        <Tab.Screen
          name="今日"
          component={TodayScreen}
          options={{ tabBarIcon: ({ color }) => <Text style={{ color }}>⏱</Text> }}
        />
        <Tab.Screen
          name="カレンダー"
          component={CalendarNavigator}
          options={{ headerShown: false, tabBarIcon: ({ color }) => <Text style={{ color }}>📅</Text> }}
        />
        <Tab.Screen
          name="設定"
          component={SettingsNavigator}
          options={{ headerShown: false, tabBarIcon: ({ color }) => <Text style={{ color }}>⚙️</Text> }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
