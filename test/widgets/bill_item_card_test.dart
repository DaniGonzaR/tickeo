import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/widgets/bill_item_card.dart';

void main() {
  group('BillItemCard Widget Tests', () {
    late BillItem testItem;
    late BillProvider mockBillProvider;
    late List<String> testParticipants;

    setUp(() {
      testItem = BillItem(
        id: 'item-1',
        name: 'Pizza Margherita',
        price: 15.99,
        selectedBy: ['user1'],
      );

      testParticipants = ['user1', 'user2', 'user3'];
      mockBillProvider = BillProvider();
    });

    Widget createTestWidget(BillItem item) {
      return MaterialApp(
        home: Scaffold(
          body: BillItemCard(
            item: item,
            participants: testParticipants,
            billProvider: mockBillProvider,
            getParticipantName: (id) => 'User $id',
          ),
        ),
      );
    }

    testWidgets('should display item name and price', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      expect(find.text('Pizza Margherita'), findsOneWidget);
      expect(find.text('€15.99'), findsOneWidget);
    });

    testWidgets('should display selected participants count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      expect(find.text('1 person selected'), findsOneWidget);
    });

    testWidgets('should display multiple participants count correctly', (WidgetTester tester) async {
      final multiSelectItem = testItem.copyWith(selectedBy: ['user1', 'user2']);
      await tester.pumpWidget(createTestWidget(multiSelectItem));

      expect(find.text('2 people selected'), findsOneWidget);
    });

    testWidgets('should display no participants when none selected', (WidgetTester tester) async {
      final unselectedItem = testItem.copyWith(selectedBy: []);
      await tester.pumpWidget(createTestWidget(unselectedItem));

      expect(find.text('No one selected'), findsOneWidget);
    });

    testWidgets('should show expand icon when collapsed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('should expand when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      // Tap to expand
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('should show participant selection when expanded', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      // Expand the card
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Should show participant selection
      expect(find.text('Who ordered this item?'), findsOneWidget);
      expect(find.text('User user1'), findsOneWidget);
      expect(find.text('User user2'), findsOneWidget);
      expect(find.text('User user3'), findsOneWidget);
    });

    testWidgets('should show checkboxes for participants when expanded', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      // Expand the card
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Should show checkboxes
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('should show correct checkbox states', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      // Expand the card
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Find checkboxes
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      
      // user1 should be checked (in selectedBy)
      expect(checkboxes[0].value, true);
      // user2 and user3 should be unchecked
      expect(checkboxes[1].value, false);
      expect(checkboxes[2].value, false);
    });

    testWidgets('should handle checkbox tap', (WidgetTester tester) async {
      // Create a bill first to enable checkbox functionality
      mockBillProvider.createManualBill('Test Bill');
      mockBillProvider.addManualItem('Pizza Margherita', 15.99);
      mockBillProvider.addParticipant('user1');
      mockBillProvider.addParticipant('user2');
      mockBillProvider.addParticipant('user3');

      await tester.pumpWidget(createTestWidget(testItem));

      // Expand the card
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Tap on user2's checkbox (should be unchecked initially)
      final user2Checkbox = tester.widgetList<Checkbox>(find.byType(Checkbox)).elementAt(1);
      expect(user2Checkbox.value, false);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
    });

    testWidgets('should display per-person cost when multiple selected', (WidgetTester tester) async {
      final multiSelectItem = testItem.copyWith(selectedBy: ['user1', 'user2']);
      await tester.pumpWidget(createTestWidget(multiSelectItem));

      expect(find.text('€7.99 per person'), findsOneWidget);
    });

    testWidgets('should not display per-person cost when one selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      expect(find.textContaining('per person'), findsNothing);
    });

    testWidgets('should handle long item names with ellipsis', (WidgetTester tester) async {
      final longNameItem = testItem.copyWith(
        name: 'This is a very long item name that should be truncated with ellipsis',
      );
      await tester.pumpWidget(createTestWidget(longNameItem));

      final textWidget = tester.widget<Text>(find.text(longNameItem.name));
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should display remove button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should handle remove button tap', (WidgetTester tester) async {
      // Create a bill with the item
      mockBillProvider.createManualBill('Test Bill');
      mockBillProvider.addManualItem('Pizza Margherita', 15.99);

      await tester.pumpWidget(createTestWidget(testItem));

      // Tap remove button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
    });

    testWidgets('should show correct styling for selected state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testItem));

      // Find the card
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should handle empty participants list', (WidgetTester tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: BillItemCard(
            item: testItem,
            participants: [],
            billProvider: mockBillProvider,
            getParticipantName: (id) => 'User $id',
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Pizza Margherita'), findsOneWidget);
      expect(find.text('€15.99'), findsOneWidget);
    });
  });
}
