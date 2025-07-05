import 'package:flutter/material.dart';
import 'dart:async';
import '../models/reception_model.dart';
import '../services/export_service.dart';

class SendPage extends StatefulWidget {
  final TransferMethodModel method;
  final int documentId;

  const SendPage({
    super.key,
    required this.method,
    required this.documentId,
  });

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  late Timer _timer;
  int _countdown = 42; // Contador inicial
  bool _isActive = true;
  bool _isExporting = false;
  bool _exportCompleted = false;
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startExportProcess();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _isActive = false;
        });
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _countdown = 42;
      _isActive = true;
    });
    _timer.cancel();
    _startTimer();
  }

  Future<void> _startExportProcess() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simular proceso de exportación
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isExporting = false;
        _exportCompleted = true;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar el documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument() async {
    try {
      // Usar el método mejorado que siempre retorna información del archivo
      final result = await _exportService.exportDocumentAsJachaWithFallback(widget.documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Intentar compartir si es posible
        try {
          await _exportService.exportAndShareDocument(widget.documentId);
        } catch (shareError) {
          print('Error al compartir (pero archivo creado): $shareError');
          // No mostrar error aquí porque el archivo se creó exitosamente
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Enviar Documento',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Título
            Text(
              'Enviar Clase',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 40),
            
            // Icono del método seleccionado
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: widget.method.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.method.color,
                  width: 3,
                ),
              ),
              child: Center(
                child: _isExporting
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.method.color),
                      strokeWidth: 6,
                    )
                  : Icon(
                      _exportCompleted ? Icons.check_circle : widget.method.icon,
                      size: 100,
                      color: _exportCompleted ? Colors.green : widget.method.color,
                    ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Barra de progreso
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _isActive ? _countdown / 42 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.method.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Tarjeta de instrucciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_isExporting)
                    const Text(
                      'Preparando documento para enviar...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (_exportCompleted)
                    Text(
                      'Documento listo para ${widget.method.name.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      widget.method.instruction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  if (!_isExporting) ...[
                    const SizedBox(height: 24),
                    
                    // Código de identificación
                    Text(
                      '2A7COD6',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contador circular
                    Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          // Círculo de fondo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                          ),
                          // Círculo de progreso
                          if (_isActive)
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: _countdown / 42,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.method.color,
                                ),
                              ),
                            ),
                          // Número en el centro
                          Center(
                            child: Text(
                              '$_countdown',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botones de acción
            if (_exportCompleted) ...[
              // Botón de compartir usando el sistema nativo
              ElevatedButton(
                onPressed: _shareDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.method.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text(
                      'Compartir documento',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Botón de reiniciar si el tiempo se agotó
            if (!_isActive && !_isExporting)
              ElevatedButton(
                onPressed: _resetTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.method.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Reiniciar envío',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            
            // Espacio adicional para el scroll
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
