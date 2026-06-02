import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../data/services/configuracao_service.dart';
import '../widgets/loading_button.dart';

class ControleDieselScreen extends StatefulWidget {
  const ControleDieselScreen({super.key});

  @override
  State<ControleDieselScreen> createState() => _ControleDieselScreenState();
}

class _ControleDieselScreenState extends State<ControleDieselScreen> {
  final _configService = ConfiguracaoService();
  final _nomeController = TextEditingController();
  final _litrosController = TextEditingController();
  final _horimetroController = TextEditingController();
  final _aplicacaoController = TextEditingController();

  List<String> _equipamentos = [];
  String _equipamentoSelecionado = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarEquipamentos();
  }

  Future<void> _carregarEquipamentos() async {
    final lista = await _configService.carregarEquipamentos();
    setState(() {
      _equipamentos = lista;
      if (lista.isNotEmpty) _equipamentoSelecionado = lista.first;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _litrosController.dispose();
    _horimetroController.dispose();
    _aplicacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Diesel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipamento
            _buildLabel('Equipamento / Veículo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selecionarEquipamento,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _equipamentoSelecionado.isEmpty
                            ? 'Selecione o equipamento'
                            : _equipamentoSelecionado,
                        style: TextStyle(
                          fontSize: 15,
                          color: _equipamentoSelecionado.isEmpty
                              ? AppTheme.textHint
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _adicionarVeiculo,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Novo Veículo'),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Seu Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: 'Nome do motorista',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Quantidade (Litros)'),
            const SizedBox(height: 8),
            TextField(
              controller: _litrosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Ex: 50.0',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Horímetro'),
            const SizedBox(height: 8),
            TextField(
              controller: _horimetroController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Ex: 1234.5',
                prefixIcon: Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Aplicação (Motivo)'),
            const SizedBox(height: 8),
            TextField(
              controller: _aplicacaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Descreva a aplicação...',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              text: 'Registrar Abastecimento',
              isLoading: _loading,
              onPressed: _registrar,
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

  void _selecionarEquipamento() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione o Equipamento'),
        children: _equipamentos.map((eq) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _equipamentoSelecionado = eq);
              Navigator.pop(context);
            },
            child: Text(eq),
          );
        }).toList(),
      ),
    );
  }

  void _adicionarVeiculo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Veículo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nome do Veículo (Ex: Caminhão 1313)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = controller.text.trim();
              if (nome.isNotEmpty) {
                await _configService.adicionarVeiculo(nome);
                setState(() {
                  _equipamentos.add(nome);
                  _equipamentoSelecionado = nome;
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registrar() async {
    final litros = double.tryParse(_litrosController.text);
    final horimetro = double.tryParse(_horimetroController.text);

    if (litros == null || horimetro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique os campos numéricos')),
      );
      return;
    }

    setState(() => _loading = true);

    final dados = {
      'data': Timestamp.now(),
      'motorista': _nomeController.text.trim(),
      'litros': litros,
      'horimetro': horimetro,
      'aplicacao': _aplicacaoController.text.trim(),
      'equipamento': _equipamentoSelecionado,
      'usuario_uid': FirebaseAuth.instance.currentUser?.uid,
    };

    try {
      await FirebaseFirestore.instance.collection('abastecimentos').add(dados);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abastecimento salvo!'),
          backgroundColor: AppTheme.aprovada,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar.')),
      );
    }
  }
}
