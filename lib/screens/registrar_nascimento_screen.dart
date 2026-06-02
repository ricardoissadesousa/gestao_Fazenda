import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/animal.dart';
import '../data/services/animal_service.dart';
import '../widgets/loading_button.dart';
import 'package:intl/intl.dart';

class RegistrarNascimentoScreen extends StatefulWidget {
  final Animal? animalParaEditar;
  const RegistrarNascimentoScreen({super.key, this.animalParaEditar});

  @override
  State<RegistrarNascimentoScreen> createState() => _RegistrarNascimentoScreenState();
}

class _RegistrarNascimentoScreenState extends State<RegistrarNascimentoScreen> {
  final _service = AnimalService();
  final _numeroBrincoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _numeroMaeController = TextEditingController();
  String _sexoSelecionado = 'Fêmea';
  bool _loading = false;

  bool get _isEdicao => widget.animalParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      final a = widget.animalParaEditar!;
      _numeroBrincoController.text = a.numero;
      _nomeController.text = a.nome;
      _dataNascimentoController.text = a.nascimento;
      _numeroMaeController.text = a.mae;
      _sexoSelecionado = a.sexo.isNotEmpty ? a.sexo : 'Fêmea';
    }
  }

  @override
  void dispose() {
    _numeroBrincoController.dispose();
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _numeroMaeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Animal' : 'Registrar Nascimento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEdicao ? Icons.edit : Icons.child_care,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Número do Brinco *'),
            const SizedBox(height: 8),
            TextField(
              controller: _numeroBrincoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 001',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Nome do Bezerro *'),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: 'Ex: Mimosa',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Sexo'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _sexoSelecionado,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
                DropdownMenuItem(value: 'Macho', child: Text('Macho')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _sexoSelecionado = val);
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('Data de Nascimento *'),
            const SizedBox(height: 8),
            TextField(
              controller: _dataNascimentoController,
              readOnly: true,
              onTap: _selecionarData,
              decoration: const InputDecoration(
                hintText: 'dd/mm/aaaa',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Número da Mãe *'),
            const SizedBox(height: 8),
            TextField(
              controller: _numeroMaeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 050',
                prefixIcon: Icon(Icons.family_restroom),
              ),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              text: _isEdicao ? 'Salvar Alterações' : 'Registrar Nascimento',
              isLoading: _loading,
              onPressed: _validarESalvar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Future<void> _selecionarData() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (date != null) {
      _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _validarESalvar() async {
    final numero = _numeroBrincoController.text.trim();
    final nome = _nomeController.text.trim();
    final mae = _numeroMaeController.text.trim();
    final data = _dataNascimentoController.text.trim();

    if (numero.isEmpty || nome.isEmpty || mae.isEmpty || data.isEmpty) {
      _mostrarErro('Preencha todos os campos obrigatórios.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(numero)) {
      _mostrarErro('Número do brinco: apenas números!');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(mae)) {
      _mostrarErro('Número da mãe: apenas números!');
      return;
    }
    if (RegExp(r'^\d+$').hasMatch(nome)) {
      _mostrarErro('O nome não pode ser um número!');
      return;
    }

    setState(() => _loading = true);

    // Verificar unicidade de número
    final numExiste = await _service.numeroExiste(
      numero,
      excluirId: widget.animalParaEditar?.id,
    );
    if (numExiste) {
      setState(() => _loading = false);
      _mostrarErro('Erro: Brinco $numero já cadastrado.');
      return;
    }

    // Verificar unicidade de nome
    final nomeExiste = await _service.nomeExiste(
      nome,
      excluirId: widget.animalParaEditar?.id,
    );
    if (nomeExiste) {
      setState(() => _loading = false);
      _mostrarErro('Erro: Animal \'$nome\' já existe.');
      return;
    }

    // Salvar
    final animal = Animal(
      id: widget.animalParaEditar?.id ?? '',
      numero: numero,
      nome: nome,
      sexo: _sexoSelecionado,
      nascimento: data,
      mae: mae,
    );

    try {
      if (_isEdicao) {
        await _service.atualizarAnimal(animal);
      } else {
        await _service.adicionarAnimal(animal);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao ? 'Dados atualizados!' : 'Nascimento registrado!'),
          backgroundColor: AppTheme.aprovada,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      _mostrarErro('Erro ao salvar dados.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.reprovada),
    );
  }
}
