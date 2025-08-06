import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

// Native functionality imports
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Global storage for saved bills
List<SavedBill> savedBills = [];

// Simple storage service for web compatibility
class StorageService {
  static const String _billsKey = 'tickeo_saved_bills';
  
  // For web, we'll use localStorage simulation
  static final Map<String, String> _webStorage = {};
  
  static Future<void> saveBills(List<SavedBill> bills) async {
    try {
      final billsJson = bills.map((bill) => bill.toJson()).toList();
      final jsonString = jsonEncode(billsJson);
      
      // For web compatibility - simulate localStorage
      _webStorage[_billsKey] = jsonString;
      
      // In a real implementation with SharedPreferences:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString(_billsKey, jsonString);
      
      print('✅ Cuentas guardadas: ${bills.length} elementos');
    } catch (e) {
      print('❌ Error guardando cuentas: $e');
    }
  }
  
  static Future<List<SavedBill>> loadBills() async {
    try {
      // For web compatibility - simulate localStorage
      final jsonString = _webStorage[_billsKey];
      
      // In a real implementation with SharedPreferences:
      // final prefs = await SharedPreferences.getInstance();
      // final jsonString = prefs.getString(_billsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('📝 No hay cuentas guardadas previamente');
        return [];
      }
      
      final billsJson = jsonDecode(jsonString) as List;
      final bills = billsJson.map((json) => SavedBill.fromJson(json)).toList();
      
      print('✅ Cuentas cargadas: ${bills.length} elementos');
      return bills;
    } catch (e) {
      print('❌ Error cargando cuentas: $e');
      return [];
    }
  }
  
  static Future<void> clearAllBills() async {
    try {
      _webStorage.remove(_billsKey);
      print('🗑️ Todas las cuentas eliminadas');
    } catch (e) {
      print('❌ Error eliminando cuentas: $e');
    }
  }
}

void main() {
  runApp(const TickeoApp());
}

class TickeoApp extends StatelessWidget {
  const TickeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tickeo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadSavedBills();
  }

  Future<void> _loadSavedBills() async {
    try {
      final loadedBills = await StorageService.loadBills();
      setState(() {
        savedBills.clear();
        savedBills.addAll(loadedBills);
      });
    } catch (e) {
      print('Error cargando cuentas: $e');
    }
  }

  void _refreshHistory() {
    setState(() {
      // Refresh the UI to show updated saved bills
    });
  }

  Future<void> _clearAllBills() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar TODAS las cuentas guardadas?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAllBills();
      setState(() {
        savedBills.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las cuentas han sido eliminadas'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickeo'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (savedBills.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllBills();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar Todas'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Bienvenido a Tickeo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Subtitle
            Text(
              'Divide cuentas automáticamente',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Main Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const BillDetailsScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve),
                        );
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                  if (result == true) {
                    _refreshHistory();
                  }
                },
                icon: const Icon(Icons.add, size: 24),
                label: const Text('Crear Cuenta Nueva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Secondary Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función disponible en la versión completa'),
                    ),
                  );
                },
                icon: const Icon(Icons.document_scanner, size: 22),
                label: const Text('Escanear Ticket', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función disponible en la versión completa'),
                    ),
                  );
                },
                icon: const Icon(Icons.group_add, size: 22),
                label: const Text('Unirse a Cuenta', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            // History Section
            if (savedBills.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Cuentas Guardadas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...savedBills.map((bill) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  title: Text(
                    bill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bill.items.length} productos • €${bill.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${bill.participants.length} personas • ${bill.date}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => BillDetailsScreen(savedBill: bill),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end).chain(
                            CurveTween(curve: curve),
                          );
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    if (result == true) {
                      _refreshHistory();
                    }
                  },
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class BillDetailsScreen extends StatefulWidget {
  final SavedBill? savedBill;
  const BillDetailsScreen({super.key, this.savedBill});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final List<BillItem> items = [];
  final List<String> participants = [];
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController participantController = TextEditingController();
  final TextEditingController billNameController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    if (widget.savedBill != null) {
      // Load existing bill data
      billNameController.text = widget.savedBill!.name;
      items.addAll(widget.savedBill!.items);
      participants.addAll(widget.savedBill!.participants);
    } else {
      // Default name for new bills
      billNameController.text = 'Cuenta ${DateTime.now().day}/${DateTime.now().month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.savedBill != null ? 'Editar Cuenta' : 'Nueva Cuenta'),
        actions: [
          IconButton(
            onPressed: _shareBill,
            icon: const Icon(Icons.share),
            tooltip: 'Compartir cuenta',
          ),
          IconButton(
            onPressed: _saveBill,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar cuenta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bill Name Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre de la Cuenta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: billNameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Ej: Cena en el restaurante',
                        labelStyle: const TextStyle(fontSize: 16),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: const Icon(Icons.edit, size: 24),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Add Item Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar Producto',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: itemController,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio €',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _addItem,
                          child: const Icon(Icons.add_shopping_cart),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Add Participant Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar Participante',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: participantController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _addParticipant,
                          child: const Icon(Icons.person_add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Items List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos (${items.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text('No hay productos agregados'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                                  final item = items[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ExpansionTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Text(
                                            '€${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: item.assignedTo.isEmpty
                                          ? const Text('Sin asignar', style: TextStyle(color: Colors.grey))
                                          : Text(
                                              '${item.assignedTo.join(", ")} (€${item.pricePerPerson.toStringAsFixed(2)} c/u)',
                                              style: TextStyle(color: Theme.of(context).primaryColor),
                                            ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeItem(index),
                                      ),
                                      children: [
                                        if (participants.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Asignar a:',
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  children: participants.map((participant) {
                                                    final isAssigned = item.assignedTo.contains(participant);
                                                    return FilterChip(
                                                      label: Text(participant),
                                                      selected: isAssigned,
                                                      onSelected: (selected) {
                                                        _toggleParticipantAssignment(index, participant);
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => _assignToAll(index),
                                                      child: const Text('Asignar a todos'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    TextButton(
                                                      onPressed: () => _clearAssignments(index),
                                                      child: const Text('Limpiar'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'Agrega participantes para asignar este producto',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    if (items.isNotEmpty) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '€${_calculateTotal().toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      

                      
                      if (participants.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        Text(
                          'Resumen por Persona:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...participants.map((participant) {
                          final personalTotal = _calculatePersonalTotal(participant);
                          final assignedItems = _getAssignedItems(participant);
                          return Card(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        participant,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '€${personalTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (assignedItems.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      assignedItems.map((item) => 
                                        '${item.name} (€${item.pricePerPerson.toStringAsFixed(2)})'
                                      ).join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            
            // Participants
            if (participants.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participantes (${participants.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: participants.map((name) => Chip(
                          label: Text(name),
                          onDeleted: () => _removeParticipant(name),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final name = itemController.text.trim();
    final priceText = priceController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el precio del producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final price = double.tryParse(priceText.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio válido mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check for duplicate product names
    if (items.any((item) => item.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un producto con ese nombre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      items.add(BillItem(
        name: name,
        price: price,
      ));
      itemController.clear();
      priceController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto "$name" agregado correctamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addParticipant() {
    final name = participantController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del participante'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 2 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check for duplicate participant names
    if (participants.any((participant) => participant.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un participante con ese nombre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      participants.add(name);
      participantController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Participante "$name" agregado correctamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeItem(int index) async {
    final item = items[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Producto'),
          content: Text('¿Estás seguro de que quieres eliminar "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      setState(() {
        items.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto "${item.name}" eliminado'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeParticipant(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Participante'),
          content: Text(
            '¿Estás seguro de que quieres eliminar a "$name"?\n\n'
            'Esto también lo eliminará de todos los productos asignados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      setState(() {
        participants.remove(name);
        // Remove participant from all item assignments
        for (int i = 0; i < items.length; i++) {
          if (items[i].assignedTo.contains(name)) {
            items[i] = items[i].copyWith(
              assignedTo: items[i].assignedTo.where((p) => p != name).toList(),
            );
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Participante "$name" eliminado'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleParticipantAssignment(int itemIndex, String participant) {
    setState(() {
      final item = items[itemIndex];
      List<String> newAssignedTo = List.from(item.assignedTo);
      
      if (newAssignedTo.contains(participant)) {
        newAssignedTo.remove(participant);
      } else {
        newAssignedTo.add(participant);
      }
      
      items[itemIndex] = item.copyWith(assignedTo: newAssignedTo);
    });
  }

  void _assignToAll(int itemIndex) {
    setState(() {
      items[itemIndex] = items[itemIndex].copyWith(
        assignedTo: List.from(participants),
      );
    });
  }

  void _clearAssignments(int itemIndex) {
    setState(() {
      items[itemIndex] = items[itemIndex].copyWith(assignedTo: []);
    });
  }

  double _calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.price);
  }





  double _calculatePersonalTotal(String participant) {
    return items
        .where((item) => item.assignedTo.contains(participant))
        .fold(0.0, (sum, item) => sum + item.pricePerPerson);
  }

  List<BillItem> _getAssignedItems(String participant) {
    return items.where((item) => item.assignedTo.contains(participant)).toList();
  }

  void _shareBill() {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos para compartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showShareDialog();
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.share, color: Colors.blue),
              SizedBox(width: 8),
              Text('Compartir Cuenta'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.green),
                title: const Text('Copiar Resumen'),
                subtitle: const Text('Copiar al portapapeles'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Compartir como Texto'),
                subtitle: const Text('Enviar por WhatsApp, SMS, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.purple),
                title: const Text('Generar Código QR'),
                subtitle: const Text('Para unirse rápidamente'),
                onTap: () {
                  Navigator.pop(context);
                  _showQRCode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.orange),
                title: const Text('Generar Enlace'),
                subtitle: const Text('Crear enlace para compartir'),
                onTap: () {
                  Navigator.pop(context);
                  _generateShareLink();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard() {
    final summary = _generateTextSummary();
    Clipboard.setData(ClipboardData(text: summary));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Resumen copiado al portapapeles'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareAsText() async {
    final summary = _generateTextSummary();
    
    try {
      // Use native sharing if available (mobile/desktop)
      await Share.share(
        summary,
        subject: 'Cuenta de Tickeo - ${billNameController.text}',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.share, color: Colors.white),
              SizedBox(width: 8),
              Text('Compartiendo cuenta...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Fallback to clipboard for web or if native sharing fails
      Clipboard.setData(ClipboardData(text: summary));
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Texto Copiado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('El resumen ha sido copiado al portapapeles.'),
              const SizedBox(height: 16),
              const Text('Puedes pegarlo en:'),
              const SizedBox(height: 8),
              const Text('• WhatsApp'),
              const Text('• SMS'),
              const Text('• Email'),
              const Text('• Cualquier aplicación de mensajería'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  void _showQRCode() {
    final billData = _generateShareData();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escanea este código para unirte a la cuenta:'),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: billData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Datos: ${billData.length} caracteres',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: billData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos copiados al portapapeles'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copiar Datos'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _generateShareLink() {
    final billData = _generateShareData();
    final encodedData = Uri.encodeComponent(billData);
    final shareLink = 'https://tickeo.app/join?data=$encodedData';
    
    Clipboard.setData(ClipboardData(text: shareLink));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enlace Generado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enlace copiado al portapapeles:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Text(
                shareLink,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comparte este enlace para que otros se unan a la cuenta.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final uri = Uri.parse(shareLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se puede abrir el enlace'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error abriendo enlace: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Abrir Enlace'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _generateTextSummary() {
    final billName = billNameController.text.trim();
    final total = _calculateTotal();
    final buffer = StringBuffer();
    
    buffer.writeln('📋 CUENTA: $billName');
    buffer.writeln('📅 ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('');
    buffer.writeln('🛒 PRODUCTOS:');
    
    for (final item in items) {
      buffer.writeln('• ${item.name}: €${item.price.toStringAsFixed(2)}');
      if (item.assignedTo.isNotEmpty) {
        buffer.writeln('  👥 ${item.assignedTo.join(", ")} (€${item.pricePerPerson.toStringAsFixed(2)} c/u)');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('💰 TOTAL: €${total.toStringAsFixed(2)}');
    
    if (participants.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('👥 RESUMEN POR PERSONA:');
      for (final participant in participants) {
        final personalTotal = _calculatePersonalTotal(participant);
        buffer.writeln('• $participant: €${personalTotal.toStringAsFixed(2)}');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('📱 Generado con Tickeo');
    
    return buffer.toString();
  }

  String _generateShareData() {
    final billName = billNameController.text.trim();
    final data = {
      'name': billName,
      'items': items.map((item) => {
        'name': item.name,
        'price': item.price,
        'assignedTo': item.assignedTo,
      }).toList(),
      'participants': participants,
      'created': DateTime.now().toIso8601String(),
    };
    
    return data.toString();
  }

  void _saveBill() async {
    if (billNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre para la cuenta')),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    
    final newBill = SavedBill(
      name: billNameController.text,
      items: List.from(items),
      participants: List.from(participants),
      total: _calculateTotal(),
      date: dateStr,
    );

    if (widget.savedBill != null) {
      // Update existing bill
      final index = savedBills.indexWhere((bill) => bill == widget.savedBill);
      if (index != -1) {
        savedBills[index] = newBill;
      }
    } else {
      // Add new bill
      savedBills.add(newBill);
    }

    // Save to persistent storage
    await StorageService.saveBills(savedBills);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cuenta "${billNameController.text}" guardada correctamente'),
        backgroundColor: Colors.green,
      ),
    );

    // Return to home screen and refresh
    Navigator.pop(context, true);
  }
}

class BillItem {
  final String name;
  final double price;
  final List<String> assignedTo;

  BillItem({
    required this.name, 
    required this.price,
    List<String>? assignedTo,
  }) : assignedTo = assignedTo ?? [];

  // Calculate price per person for this item
  double get pricePerPerson {
    if (assignedTo.isEmpty) return 0.0;
    return price / assignedTo.length;
  }

  // Create a copy with updated assigned participants
  BillItem copyWith({
    String? name,
    double? price,
    List<String>? assignedTo,
  }) {
    return BillItem(
      name: name ?? this.name,
      price: price ?? this.price,
      assignedTo: assignedTo ?? List.from(this.assignedTo),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'assignedTo': assignedTo,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      assignedTo: List<String>.from(json['assignedTo'] ?? []),
    );
  }
}

class SavedBill {
  final String name;
  final List<BillItem> items;
  final List<String> participants;
  final double total;
  final String date;

  SavedBill({
    required this.name,
    required this.items,
    required this.participants,
    required this.total,
    required this.date,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'participants': participants,
      'total': total,
      'date': date,
    };
  }

  factory SavedBill.fromJson(Map<String, dynamic> json) {
    return SavedBill(
      name: json['name'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((itemJson) => BillItem.fromJson(itemJson))
          .toList(),
      participants: List<String>.from(json['participants'] ?? []),
      total: (json['total'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
    );
  }
}
