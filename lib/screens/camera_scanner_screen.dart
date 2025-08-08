import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tickeo/services/notification_service.dart';
import 'package:tickeo/services/ocr_service.dart';
import 'package:tickeo/utils/app_colors.dart';

class CameraScannerScreen extends StatefulWidget {
  final String scanType; // 'ticket' or 'qr'
  
  const CameraScannerScreen({
    super.key,
    required this.scanType,
  });

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Web compatibility: Use file upload for OCR instead of camera
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.scanType == 'ticket' ? 'Escanear Ticket' : 'Escanear QR'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.scanType == 'ticket' ? Icons.receipt_long : Icons.qr_code,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.scanType == 'ticket' ? 'Subir Imagen de Ticket' : 'Subir Imagen de QR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.scanType == 'ticket' 
                    ? 'Selecciona una imagen de tu ticket para extraer los productos y precios automáticamente.'
                    : 'Selecciona una imagen con el código QR para unirte a la cuenta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Procesando imagen...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Seleccionar Imagen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.scanType == 'ticket' ? 'Escanear Ticket' : 'Escanear QR',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return Column(
            children: [
              // Camera preview area (simulated)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Simulated camera view
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.scanType == 'ticket' 
                                ? Icons.receipt_long
                                : Icons.qr_code,
                              size: isMobile ? 80 : 60,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.scanType == 'ticket'
                                ? 'Coloca el ticket dentro del marco'
                                : 'Coloca el código QR dentro del marco',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 16 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Scanning frame overlay
                      Center(
                        child: Container(
                          width: isMobile ? 250 : 200,
                          height: isMobile ? 200 : 160,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Controls area
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 20 : 16),
                  child: Column(
                    children: [
                      // Instructions
                      Text(
                        widget.scanType == 'ticket'
                          ? 'Toca el botón de cámara para capturar el ticket o selecciona una imagen de la galería'
                          : 'Toca el botón de cámara para escanear el código QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery button (only for tickets)
                          if (widget.scanType == 'ticket')
                            _buildActionButton(
                              icon: Icons.photo_library,
                              label: 'Galería',
                              onPressed: _isProcessing ? null : _pickFromGallery,
                              isMobile: isMobile,
                            ),
                          
                          // Camera button
                          _buildActionButton(
                            icon: Icons.camera_alt,
                            label: 'Cámara',
                            onPressed: _isProcessing ? null : _takePhoto,
                            isMobile: isMobile,
                            isPrimary: true,
                          ),
                        ],
                      ),
                      
                      if (_isProcessing) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.scanType == 'ticket'
                            ? 'Procesando ticket...'
                            : 'Escaneando QR...',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isMobile,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: isMobile ? 60 : 50,
          height: isMobile ? 60 : 50,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : Colors.grey[800],
            shape: BoxShape.circle,
            border: Border.all(
              color: isPrimary ? AppColors.primary : Colors.grey[600]!,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 24 : 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 12 : 10,
          ),
        ),
      ],
    );
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _processImage(photo);
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showConfirmationDialog(
          context: context,
          title: 'Error de Cámara',
          message: 'No se pudo acceder a la cámara. Verifica los permisos.',
          confirmText: 'OK',
          cancelText: '',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showConfirmationDialog(
          context: context,
          title: 'Error de Galería',
          message: 'No se pudo acceder a la galería.',
          confirmText: 'OK',
          cancelText: '',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImage(dynamic imageFile) async {
    try {
      if (widget.scanType == 'ticket') {
        // Process ticket with OCR
        final ocrResult = await OCRService().processReceiptImage(imageFile);
        
        if (mounted) {
          Navigator.of(context).pop(ocrResult);
        }
      } else {
        // Process QR code
        // For now, we'll simulate QR processing
        // In a real implementation, you'd use a QR decoder
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pop({
            'type': 'qr',
            'data': 'mock_bill_id_123',
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showConfirmationDialog(
          context: context,
          title: 'Error de Procesamiento',
          message: 'No se pudo procesar la imagen: ${e.toString()}',
          confirmText: 'OK',
          cancelText: '',
        );
      }
    }
  }
}
