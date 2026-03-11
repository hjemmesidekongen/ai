# expo-native-ui — Process Reference

## Platform-Specific Code Patterns

### Platform.select

```tsx
import { Platform, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  container: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.15,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
});
```

### File-Based Platform Splits

```
Button.tsx           // shared fallback
Button.ios.tsx       // iOS-specific implementation
Button.android.tsx   // Android-specific implementation
```

Metro resolves `.ios.tsx` / `.android.tsx` automatically. Use this pattern when the implementations diverge substantially — a few `Platform.OS` checks don't warrant splitting.

---

## SafeAreaView

Always use `react-native-safe-area-context`, not the core RN version:

```tsx
import { SafeAreaView } from 'react-native-safe-area-context';

function Screen({ children }: { children: React.ReactNode }) {
  return <SafeAreaView style={{ flex: 1 }}>{children}</SafeAreaView>;
}
```

For programmatic insets (e.g., custom tab bar positioning):

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';

function TabBar() {
  const insets = useSafeAreaInsets();
  return <View style={{ paddingBottom: insets.bottom + 8 }}>...</View>;
}
```

---

## Navigation Patterns (expo-router)

### File-Based Route Structure

```
app/
  _layout.tsx          // root layout — wraps all screens
  index.tsx            // maps to "/"
  (tabs)/
    _layout.tsx        // tab navigator layout
    home.tsx
    profile.tsx
  user/
    [id].tsx           // dynamic segment — /user/123
```

### Programmatic Navigation

```tsx
import { useRouter, useLocalSearchParams } from 'expo-router';

function ProfileScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <View>
      <Text>User {id}</Text>
      <Button title="Go back" onPress={() => router.back()} />
      <Button title="Settings" onPress={() => router.push('/settings')} />
    </View>
  );
}
```

### Typed Routes

Enable typed routes in `app.json`:

```json
{ "expo": { "experiments": { "typedRoutes": true } } }
```

---

## Gesture Handling

### App Setup

Wrap the root in `GestureHandlerRootView`:

```tsx
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack />
    </GestureHandlerRootView>
  );
}
```

### Basic Gesture

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';

function DraggableCard() {
  const offsetX = useSharedValue(0);
  const offsetY = useSharedValue(0);

  const pan = Gesture.Pan()
    .onUpdate((e) => {
      offsetX.value = e.translationX;
      offsetY.value = e.translationY;
    })
    .onEnd(() => {
      offsetX.value = withSpring(0);
      offsetY.value = withSpring(0);
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: offsetX.value }, { translateY: offsetY.value }],
  }));

  return (
    <GestureDetector gesture={pan}>
      <Animated.View style={[styles.card, animatedStyle]} />
    </GestureDetector>
  );
}
```

### Composing Conflicting Gestures

```tsx
// Simultaneous: both fire
const combined = Gesture.Simultaneous(pan, pinch);

// Exclusive: first recognized wins
const exclusive = Gesture.Exclusive(swipe, tap);
```

---

## Animations

### Reanimated — Spring and Timing

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  Easing,
} from 'react-native-reanimated';

function FadeInView({ children }: { children: React.ReactNode }) {
  const opacity = useSharedValue(0);

  useEffect(() => {
    opacity.value = withTiming(1, { duration: 300, easing: Easing.out(Easing.quad) });
  }, []);

  const style = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return <Animated.View style={style}>{children}</Animated.View>;
}
```

### Reanimated — Layout Animations

```tsx
import Animated, { FadeIn, FadeOut, Layout } from 'react-native-reanimated';

function AnimatedItem({ item }: { item: Item }) {
  return (
    <Animated.View entering={FadeIn} exiting={FadeOut} layout={Layout.springify()}>
      <Text>{item.label}</Text>
    </Animated.View>
  );
}
```

### LayoutAnimation (simpler, less control)

```tsx
import { LayoutAnimation, UIManager, Platform } from 'react-native';

if (Platform.OS === 'android') {
  UIManager.setLayoutAnimationEnabledExperimental?.(true);
}

function toggleExpand() {
  LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
  setExpanded(prev => !prev);
}
```

Use `LayoutAnimation` only for simple expand/collapse. For anything animated continuously or gesture-driven, use Reanimated.

---

## Styling

### StyleSheet.create

```tsx
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  title: { fontSize: 18, fontWeight: '600', color: '#111' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
```

### Responsive Sizing

```tsx
import { useWindowDimensions } from 'react-native';

function ResponsiveImage() {
  const { width } = useWindowDimensions(); // reactive to orientation
  return <Image style={{ width: width * 0.9, height: width * 0.5 }} source={...} />;
}
```

---

## Design System Tokens

```ts
// tokens.ts
export const colors = {
  primary: '#0066FF',
  background: '#FFFFFF',
  surface: '#F5F5F5',
  text: { primary: '#111', secondary: '#666' },
};

export const spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 };

export const radius = { sm: 4, md: 8, lg: 16, full: 9999 };

export const typography = {
  body: { fontSize: 16, lineHeight: 24 },
  caption: { fontSize: 12, lineHeight: 18 },
  heading: { fontSize: 24, fontWeight: '700' as const },
};
```

---

## Icons

```tsx
import { Ionicons } from '@expo/vector-icons';

<Ionicons name="checkmark-circle" size={24} color={colors.primary} />
```

Full icon set list: icons.expo.fyi

---

## Image Handling

```tsx
import { Image } from 'expo-image';

<Image
  source={{ uri: 'https://example.com/photo.jpg' }}
  placeholder={{ blurhash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4' }}
  contentFit="cover"
  transition={200}
  style={{ width: 200, height: 200 }}
/>
```

`expo-image` has better memory management, blurhash placeholders, and disk caching compared to core `Image`.

---

## Lists — FlashList vs FlatList

### FlashList (preferred for long lists)

```tsx
import { FlashList } from '@shopify/flash-list';

<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow item={item} />}
  estimatedItemSize={64}  // accurate estimate matters for performance
  keyExtractor={(item) => item.id}
/>
```

### FlatList (acceptable for short/simple lists)

```tsx
<FlatList
  data={items}
  renderItem={({ item }) => <ItemRow item={item} />}
  keyExtractor={(item) => item.id}
/>
```

Threshold: use FlashList when items exceed ~50 or list length is unbounded.

---

## Modals and Bottom Sheets

### Bottom Sheet (@gorhom/bottom-sheet)

```tsx
import BottomSheet, { BottomSheetView } from '@gorhom/bottom-sheet';

function FilterSheet() {
  const sheetRef = useRef<BottomSheet>(null);
  const snapPoints = useMemo(() => ['40%', '80%'], []);

  return (
    <BottomSheet ref={sheetRef} snapPoints={snapPoints} index={-1} enablePanDownToClose>
      <BottomSheetView style={{ flex: 1, padding: 16 }}>
        <FilterForm />
      </BottomSheetView>
    </BottomSheet>
  );
}
```

### Modal (simple confirmations)

```tsx
import { Modal, View, Text, Pressable } from 'react-native';

<Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
  <View style={styles.overlay}>
    <View style={styles.dialog}>
      <Text>Are you sure?</Text>
      <Pressable onPress={onConfirm}><Text>Confirm</Text></Pressable>
    </View>
  </View>
</Modal>
```

---

## Anti-Patterns

### Inline style objects

```tsx
// Bad — new object on every render, breaks memoized children
<View style={{ flex: 1, padding: 16 }}>

// Good
<View style={styles.container}>
```

### Using Dimensions.get instead of useWindowDimensions

```tsx
// Bad — static, doesn't update on rotation
const { width } = Dimensions.get('window');

// Good
const { width } = useWindowDimensions();
```

### JS-thread animations

```tsx
// Bad — runs on JS thread, drops frames under load
<Animated.View style={{ opacity: animValue }} />  // using Animated API from core RN

// Good — runs on UI thread
// use react-native-reanimated useAnimatedStyle
```

### Missing keyboard avoidance on forms

```tsx
// Add KeyboardAvoidingView around form screens
import { KeyboardAvoidingView } from 'react-native';

<KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={{ flex: 1 }}>
  <FormContent />
</KeyboardAvoidingView>
```

### Touching SafeAreaView from core RN

```tsx
// Bad — deprecated, inconsistent across Expo SDK versions
import { SafeAreaView } from 'react-native';

// Good
import { SafeAreaView } from 'react-native-safe-area-context';
```
