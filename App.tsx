import React from 'react';
import {StyleSheet, View} from 'react-native';

import {Component} from './src/modules/Component';

const App = () => {
  return (
    <View style={styles.container}>
      <Component />
    </View>
  );
};

export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
