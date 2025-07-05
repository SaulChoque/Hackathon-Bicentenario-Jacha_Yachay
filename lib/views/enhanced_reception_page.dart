import 'package:flutter/material.dart';
import 'dart:async';
import '../models/reception_model.dart';
import '../models/database_models.dart';
import '../services/transfer_service.dart';
import '../services/wifi_transfer_service.dart';
import '../services/class_service.dart';
import 'document_received_success_page.dart';

class EnhancedReceptionPage extends StatefulWidget {
  final TransferMethodModel method;

  const EnhancedReceptionPage({
    super.key,
    required this.method,
  });

  @override
  State<EnhancedReceptionPage> createState() => _EnhancedReceptionPageState();
}

class _EnhancedReceptionPageState extends State<EnhancedReceptionPage> {
  late Timer _timer;
  int _countdown = 42;
  bool _isActive = true;
  bool _isListening = false;
  bool _isReceiving = false;
  bool _receptionCompleted = false;
  
  final TransferService _transferService = TransferService();
  WiFiTransferService? _wifiService;
  
  // Opción para usar servicios reales
  bool _useRealTransfer = true;
  
  String _status = 'Esperando conexión...';
  List<String> _receivedDocuments = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startListening();
  }

  @override
  void dispose() {
    _timer.cancel();
    
    // Detener servicios según el tipo y si se están usando servicios reales
    if (_useRealTransfer) {
      if (widget.method.method == TransferMethod.wifi) {
        _wifiService?.stopReceiver();
      } else if (widget.method.method == TransferMethod.nfc) {
        _transferService.stopNFCReceiver();
      }
    }
    
    // Detener visibilidad simulada
    _transferService.stopVisibility(widget.method.method);
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
          _isListening = false;
          _status = 'Tiempo de espera agotado';
        });
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _countdown = 42;
      _isActive = true;
      _receptionCompleted = false;
      _receivedDocuments.clear();
    });
    _timer.cancel();
    _startTimer();
    _startListening();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _status = 'Configurando visibilidad...';
    });

    try {
      bool success = false;
      
      if (_useRealTransfer) {
        // Usar servicios reales
        await _transferService.initializeRealServices();
        
        if (widget.method.method == TransferMethod.wifi) {
          // Crear WiFiTransferService con callback para documentos recibidos
          _wifiService = WiFiTransferService(
            onDocumentReceived: (DocumentComplete document) {
              _onDocumentReceived(document);
            },
          );
          
          success = await _wifiService!.startReceiver();
          if (success) {
            setState(() {
              _status = 'Servidor WiFi iniciado - Dispositivo visible para recepción WiFi';
            });
          }
        } else if (widget.method.method == TransferMethod.nfc) {
          success = await _transferService.startNFCReceiver();
          if (success) {
            setState(() {
              _status = 'NFC activado - Acerque el dispositivo emisor';
            });
          }
        } else {
          // Otros métodos usan lógica simulada
          success = await _transferService.makeVisibleForReception(widget.method.method);
        }
      } else {
        // Usar lógica simulada
        success = await _transferService.makeVisibleForReception(widget.method.method);
      }
      
      if (success && mounted) {
        if (!_useRealTransfer) {
          setState(() {
            _status = 'Dispositivo visible para ${widget.method.name.toLowerCase()}';
          });

          // Simular recepción aleatoria para modo simulado
          Timer.periodic(const Duration(seconds: 3), (timer) {
            if (!_isActive || !_isListening) {
              timer.cancel();
              return;
            }

            // 20% de probabilidad de recibir algo cada 3 segundos
            if (DateTime.now().millisecond % 5 == 0) {
              _simulateIncomingDocument();
            }
          });
        }
      } else if (mounted) {
        setState(() {
          _status = 'Error al configurar recepción';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
      }
    }
  }

  void _simulateIncomingDocument() async {
    setState(() {
      _isReceiving = true;
      _status = 'Recibiendo documento...';
    });

    try {
      final success = await _transferService.simulateReceiveDocument(
        method: widget.method.method,
        fromDevice: 'Dispositivo Emisor',
      );

      if (success) {
        setState(() {
          _receivedDocuments.add('Documento ${_receivedDocuments.length + 1}');
          _receptionCompleted = true;
          _status = 'Documento recibido exitosamente';
        });

        _showReceptionSuccess();
      } else {
        setState(() {
          _status = 'Error al recibir documento';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error en la recepción: $e';
      });
    } finally {
      setState(() {
        _isReceiving = false;
      });
    }
  }

  void _showReceptionSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Documento Recibido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El documento se ha recibido y guardado exitosamente en tu biblioteca.'),
            const SizedBox(height: 16),
            Text('Documentos recibidos en esta sesión: ${_receivedDocuments.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver a la lista de clases
            },
            child: const Text('Ver Biblioteca'),
          ),
        ],
      ),
    );
  }

  /// Importa un archivo .jacha desde el sistema de archivos
  Future<void> _importFromFile() async {
    try {
      setState(() {
        _isReceiving = true;
        _status = 'Importando archivo...';
      });

      final success = await _transferService.importJachaFile();
      
      if (mounted) {
        if (success) {
          setState(() {
            _receptionCompleted = true;
            _status = 'Archivo importado exitosamente';
            _receivedDocuments.add('Documento importado - ${DateTime.now().toString().substring(11, 16)}');
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento importado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _status = 'Error al importar archivo';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo importar el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReceiving = false;
        });
      }
    }
  }

  /// Debug WiFi status y solicitar permisos
  void _debugWiFiStatus() async {
    setState(() {
      _status = 'Ejecutando diagnóstico WiFi completo...';
    });
    
    try {
      // Realizar diagnóstico completo
      final diagnostic = await _transferService.performWiFiDiagnostic();
      
      // Mostrar resultados en diálogo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Diagnóstico WiFi'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiagnosticSection('Permisos', diagnostic['permissions']),
                  _buildDiagnosticSection('Conectividad', diagnostic['connectivity']),
                  _buildDiagnosticSection('Info de Red', diagnostic['network_info']),
                  _buildDiagnosticSection('Estado del Servidor', diagnostic['server_status']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _requestWiFiPermissions();
                },
                child: const Text('Solicitar Permisos'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
      
      setState(() {
        _status = 'Diagnóstico completado';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error en diagnóstico: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDiagnosticSection(String title, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (data is Map)
          ...data.entries.map((e) => Text('${e.key}: ${e.value}'))
        else
          Text(data.toString()),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Solicitar permisos WiFi específicos
  void _requestWiFiPermissions() async {
    setState(() {
      _status = 'Solicitando permisos WiFi...';
    });
    
    try {
      final success = await _transferService.requestWiFiPermissions();
      
      setState(() {
        _status = success 
          ? 'Permisos WiFi concedidos' 
          : 'Algunos permisos fueron denegados';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '✅ Permisos WiFi concedidos correctamente'
              : '❌ Algunos permisos fueron denegados'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error solicitando permisos: $e';
      });
    }
  }

  /// Maneja cuando se recibe un documento exitosamente
  void _onDocumentReceived(DocumentComplete document) async {
    print('📨 Documento recibido exitosamente en UI');
    
    // Detener el timer y marcarlo como completado
    _timer.cancel();
    setState(() {
      _receptionCompleted = true;
      _isReceiving = false;
      _isListening = false;
      _status = 'Documento recibido exitosamente';
    });
    
    // Esperar un momento para que la UI se actualice
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navegar a la vista de éxito con función de refresh
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentReceivedSuccessPage(
            receivedDocument: document,
            onHomePressed: () {
              // Función para refrescar las clases cuando se vaya al home
              ClassService.refreshClasses();
            },
          ),
        ),
      );
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          widget.method.name,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Título
            Text(
              'Recibir Documento',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Switch para transferencia real
            if (widget.method.method == TransferMethod.wifi || widget.method.method == TransferMethod.nfc)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Usar Transferencia Real',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _useRealTransfer,
                      onChanged: (value) {
                        setState(() {
                          _useRealTransfer = value;
                        });
                        // Reiniciar la escucha con el nuevo modo
                        _startListening();
                      },
                      activeColor: widget.method.color,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Icono del método seleccionado
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: widget.method.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.method.color, width: 3),
              ),
              child: Center(
                child: _isReceiving
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.method.color),
                      strokeWidth: 6,
                    )
                  : Icon(
                      _receptionCompleted ? Icons.check_circle : widget.method.icon,
                      size: 100,
                      color: _receptionCompleted ? Colors.green : widget.method.color,
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
            
            // Estado de recepción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Icon(
                        _isListening ? Icons.visibility : Icons.visibility_off,
                        color: _isListening ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_receivedDocuments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Documentos Recibidos:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._receivedDocuments.map((doc) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(doc),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
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
                  Text(
                    widget.method.instruction,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                  if (!_isReceiving && _isActive)
                    Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: _countdown / 42,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(widget.method.color),
                            ),
                          ),
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
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botones de acción
            Column(
              children: [
                // Botón de importar desde archivo
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isReceiving ? null : _importFromFile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.method.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: widget.method.color),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isReceiving 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_upload),
                        const SizedBox(width: 8),
                        Text(
                          _isReceiving ? 'Importando...' : 'Importar desde Archivo', 
                          style: const TextStyle(fontSize: 16)
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón de reiniciar si el tiempo se agotó
                if (!_isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.method.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Reiniciar Recepción', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Botón de debug WiFi (solo visible para WiFi)
                if (widget.method.method == TransferMethod.wifi)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _debugWiFiStatus,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Diagnosticar WiFi'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
