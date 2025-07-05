import 'package:flutter/material.dart';

class PruebasView extends StatefulWidget {
  const PruebasView({super.key});

  @override
  State<PruebasView> createState() => _PruebasViewState();
}

class _PruebasViewState extends State<PruebasView> {
  int? selectedOption1;
  bool? selectedOption2;
  final TextEditingController openAnswerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Preguntas de Evaluación'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pregunta de selección múltiple
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Cuántas aplicaciones debe desarrollar cada grupo?',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                RadioListTile<int>(
                  value: 1,
                  groupValue: selectedOption1,
                  onChanged: (v) => setState(() => selectedOption1 = v),
                  title: const Text('Una aplicación', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.blue,
                ),
                RadioListTile<int>(
                  value: 2,
                  groupValue: selectedOption1,
                  onChanged: (v) => setState(() => selectedOption1 = v),
                  title: const Text('Dos aplicaciones', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.blue,
                ),
                RadioListTile<int>(
                  value: 3,
                  groupValue: selectedOption1,
                  onChanged: (v) => setState(() => selectedOption1 = v),
                  title: const Text('Tres aplicaciones', style: TextStyle(color: Colors.green)),
                  activeColor: Colors.green,
                ),
                RadioListTile<int>(
                  value: 4,
                  groupValue: selectedOption1,
                  onChanged: (v) => setState(() => selectedOption1 = v),
                  title: const Text('Cuatro aplicaciones', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          // Pregunta de verdadero/falso
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Las aplicaciones deben usar bases de datos externas?',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                CheckboxListTile(
                  value: selectedOption2 == true,
                  onChanged: (v) => setState(() => selectedOption2 = v!),
                  title: const Text('Verdadero', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.blue,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: selectedOption2 == false,
                  onChanged: (v) => setState(() => selectedOption2 = !v!),
                  title: const Text('Falso', style: TextStyle(color: Colors.white)),
                  activeColor: Colors.blue,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (selectedOption2 == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Respuesta correcta: Falso',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          // Pregunta de respuesta abierta
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Qué lenguaje se debe usar para desarrollar las aplicaciones?',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: openAnswerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu respuesta...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}