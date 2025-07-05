import 'package:flutter/material.dart';
import 'dart:async';
import '../models/reception_model.dart';
import '../services/transfer_service.dart';

class EnhancedSendPage extends StatefulWidget {
  final TransferMethodModel method;
  final int documentId;

  const EnhancedSendPage({
    super.key,
    required this.method,
    required this.documentId,
  });

  @override
  State<EnhancedSendPage> createState() => _EnhancedSendPageState();
}

class _EnhancedSendPageState extends State<EnhancedSendPage> {
  late Timer _timer;
  int _countdown = 42;
  bool _isActive = true;
  bool _isScanning = false;
  bool _isTransferring = false;
  bool _transferCompleted = false;
  
  final TransferService _transferService = TransferService();
  
  // Opción para usar servicios reales
  bool _useRealTransfer = true;
  
  List<Map<String, dynamic>> _availableDevices = [];
  Set<String> _selectedDevices = {};
  Map<String, bool> _transferResults = {};
  
  StreamSubscription<List<Map<String, dynamic>>>? _deviceScanSubscription;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeDeviceScanning();
  }

  @override
  void dispose() {
    _timer.cancel();
    _deviceScanSubscription?.cancel();
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

  void _initializeDeviceScanning() {
    if (widget.method.method != TransferMethod.nfc) {
      _startDeviceScanning();
    }
  }

  void _startDeviceScanning() {
    setState(() {
      _isScanning = true;
    });

    if (_useRealTransfer && widget.method.method == TransferMethod.wifi) {
      // Usar escaneo WiFi real
      _startRealWiFiScanning();
    } else {
      // Usar escaneo simulado
      _startSimulatedScanning();
    }
  }

  void _startRealWiFiScanning() async {
    try {
      // Inicializar servicios reales si es necesario
      await _transferService.initializeRealServices();
      
      // Obtener dispositivos WiFi reales
      final devices = await _transferService.scanWiFiDevices();
      
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error escaneando dispositivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startSimulatedScanning() {
    _deviceScanSubscription = _transferService
        .scanForDevices(widget.method.method)
        .listen((devices) {
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });
    });
  }

  Future<void> _sendToSelectedDevices() async {
    if (_selectedDevices.isEmpty && widget.method.method != TransferMethod.nfc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un dispositivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTransferring = true;
      _transferResults.clear();
    });

    try {
      Map<String, bool> results;
      
      if (widget.method.method == TransferMethod.nfc) {
        // NFC real o simulado
        bool success;
        if (_useRealTransfer) {
          success = await _transferService.sendViaNFC(documentId: widget.documentId);
        } else {
          success = await _transferService.sendP2PDirect(
            documentId: widget.documentId,
            method: widget.method.method,
          );
        }
        results = {'nfc_direct': success};
      } else if (_useRealTransfer && widget.method.method == TransferMethod.wifi) {
        // WiFi real - enviar a cada dispositivo seleccionado
        results = {};
        for (String deviceId in _selectedDevices) {
          final device = _availableDevices.firstWhere((d) => d['id'] == deviceId);
          final targetIP = device['ip'] as String;
          
          final success = await _transferService.sendViaWiFi(
            documentId: widget.documentId,
            targetIP: targetIP,
          );
          
          results[deviceId] = success;
        }
      } else {
        // Usar transferencia simulada para otros métodos
        results = await _transferService.sendToMultipleDevices(
          documentId: widget.documentId,
          method: widget.method.method,
          deviceIds: _selectedDevices.toList(),
        );
      }

      setState(() {
        _transferResults = results;
        _isTransferring = false;
        _transferCompleted = true;
      });

      _showTransferResults();

    } catch (e) {
      setState(() {
        _isTransferring = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la transferencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendViaThirdParty() async {
    try {
      setState(() {
        _isTransferring = true;
      });

      final success = await _transferService.sendViaThirdParty(widget.documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Archivo compartido exitosamente' 
              : 'No se pudo compartir el archivo'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  void _showTransferResults() {
    final successful = _transferResults.values.where((result) => result).length;
    final total = _transferResults.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultados de Transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enviado exitosamente: $successful de $total dispositivos'),
            const SizedBox(height: 16),
            ..._transferResults.entries.map((entry) {
              final deviceName = _getDeviceName(entry.key);
              final icon = entry.value ? Icons.check_circle : Icons.error;
              final color = entry.value ? Colors.green : Colors.red;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(deviceName)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getDeviceName(String deviceId) {
    if (deviceId == 'nfc_direct') return 'Transferencia NFC Directa';
    
    final device = _availableDevices.firstWhere(
      (device) => device['id'] == deviceId,
      orElse: () => {'name': 'Dispositivo Desconocido'},
    );
    return device['name'];
  }

  /// Debug WiFi status y solicitar permisos
  void _debugWiFiStatus() async {
    setState(() {
      _isScanning = true;
    });
    
    try {
      // Realizar diagnóstico completo
      final diagnostic = await _transferService.performWiFiDiagnostic();
      
      setState(() {
        _isScanning = false;
      });
      
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
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en diagnóstico: $e'),
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
      _isScanning = true;
    });
    
    try {
      final success = await _transferService.requestWiFiPermissions();
      
      setState(() {
        _isScanning = false;
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
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error solicitando permisos: $e'),
            backgroundColor: Colors.red,
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
              'Enviar Documento',
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
                        // Reiniciar escaneo con el nuevo modo
                        if (widget.method.method != TransferMethod.nfc) {
                          _startDeviceScanning();
                        }
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
                child: _isTransferring
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.method.color),
                      strokeWidth: 6,
                    )
                  : Icon(
                      _transferCompleted ? Icons.check_circle : widget.method.icon,
                      size: 100,
                      color: _transferCompleted ? Colors.green : widget.method.color,
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
            
            // Lista de dispositivos disponibles (excepto NFC)
            if (widget.method.method != TransferMethod.nfc) ...[
              _buildDevicesList(),
              const SizedBox(height: 24),
            ],
            
            // Instrucciones
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
                  if (!_isTransferring && !_transferCompleted)
                    _buildCountdownCircle(),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Dispositivos Disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _startDeviceScanning,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_availableDevices.isEmpty && !_isScanning)
            const Text(
              'No se encontraron dispositivos disponibles',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._availableDevices.map((device) {
              final isOnline = device['isOnline'] as bool;
              final deviceId = device['id'] as String;
              final deviceName = device['name'] as String;
              
              return CheckboxListTile(
                title: Text(deviceName),
                subtitle: Text(isOnline ? 'Disponible' : 'Sin conexión'),
                value: _selectedDevices.contains(deviceId),
                onChanged: isOnline ? (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDevices.add(deviceId);
                    } else {
                      _selectedDevices.remove(deviceId);
                    }
                  });
                } : null,
                secondary: Icon(
                  isOnline ? Icons.circle : Icons.circle_outlined,
                  color: isOnline ? Colors.green : Colors.grey,
                  size: 12,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCountdownCircle() {
    return Container(
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
          if (_isActive)
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón principal de envío
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isTransferring ? null : _sendToSelectedDevices,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.method.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isTransferring
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Enviando...'),
                  ],
                )
              : Text(
                  widget.method.method == TransferMethod.nfc
                    ? 'Iniciar Transferencia NFC'
                    : 'Enviar a Dispositivos Seleccionados',
                  style: const TextStyle(fontSize: 16),
                ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botón de envío mediante terceros
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _sendViaThirdParty,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.method.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              side: BorderSide(color: widget.method.color),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share),
                SizedBox(width: 8),
                Text('Enviar mediante Terceros', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botón de reiniciar si el tiempo se agotó
        if (!_isActive && !_isTransferring)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Reiniciar Envío', style: TextStyle(fontSize: 16)),
            ),
          ),
      ],
    );
  }
}
