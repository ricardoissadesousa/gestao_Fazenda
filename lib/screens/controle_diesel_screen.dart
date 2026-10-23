import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../core/utils/app_error_messages.dart';
import '../data/services/abastecimento_service.dart';
import '../widgets/loading_button.dart';
import '../core/utils/fazenda_helper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/fazenda_provider.dart';

class ControleDieselScreen extends StatefulWidget {
  const ControleDieselScreen({super.key});

  @override
  State<ControleDieselScreen> createState() => _ControleDieselScreenState();
}

class _ControleDieselScreenState extends State<ControleDieselScreen> {
  final _service = AbastecimentoService();
  final _nomeController = TextEditingController();
  final _litrosController = TextEditingController();
  final _horimetroController = TextEditingController();
  final _aplicacaoController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<String> _equipamentos = [];
  String _equipamentoSelecionado = '';
  bool _loading = false;
  bool _carregandoEquipamentos = false;
  String? _fazendaDosEquipamentos;
  File? _fotoSelecionada;

  @override
  void initState() {
    super.initState();
    _recuperarFotoInterrompida();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Registra dependencia dos dois providers. Assim, se a fazenda do gestor
    // terminar de carregar depois que a tela abriu (ou o funcionario trocar de
    // fazenda), a lista e consultada novamente.
    context.watch<AuthProvider>();
    context.watch<FazendaProvider>();
    final fazendaId = FazendaHelper.obterFazendaIdAtual(context);

    if (fazendaId != null &&
        fazendaId != _fazendaDosEquipamentos &&
        !_carregandoEquipamentos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _carregarEquipamentos(fazendaId);
      });
    }
  }

  /// No Android, o sistema pode encerrar o app enquanto a câmera está
  /// aberta. Recupera a foto quando o app volta para primeiro plano.
  Future<void> _recuperarFotoInterrompida() async {
    try {
      final resposta = await _imagePicker.retrieveLostData();
      if (resposta.isEmpty || !mounted) return;

      final arquivos = resposta.files;
      if (arquivos != null && arquivos.isNotEmpty) {
        setState(() => _fotoSelecionada = File(arquivos.first.path));
      }
    } catch (erro) {
      debugPrint('Erro ao recuperar foto da câmera: $erro');
    }
  }

  Future<void> _carregarEquipamentos(String fazendaId) async {
    if (_carregandoEquipamentos) return;
    _carregandoEquipamentos = true;

    try {
      final lista = await _service.carregarVeiculos(fazendaId);
      if (!mounted) return;
      setState(() {
        _fazendaDosEquipamentos = fazendaId;
        _equipamentos = lista;
        _equipamentoSelecionado = lista.isEmpty ? '' : lista.first;
      });
    } on FirebaseException catch (erro) {
      debugPrint(
        'Erro Firebase ao carregar veiculos: ${erro.code} - ${erro.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErroVeiculo(erro, carregando: true))),
      );
    } catch (erro) {
      debugPrint('Erro ao carregar veiculos: $erro');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel carregar os veiculos.')),
      );
    } finally {
      _carregandoEquipamentos = false;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _litrosController.dispose();
    _horimetroController.dispose();
    _aplicacaoController.dispose();
    super.dispose();
  }

  /// Abre a câmera para tirar foto
  Future<void> _tirarFoto() async {
    await _selecionarFoto(ImageSource.camera);
  }

  /// Abre a galeria para escolher foto
  Future<void> _escolherDaGaleria() async {
    await _selecionarFoto(ImageSource.gallery);
  }

  Future<void> _selecionarFoto(ImageSource origem) async {
    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: origem,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (foto != null && mounted) {
        setState(() => _fotoSelecionada = File(foto.path));
      }
    } catch (erro) {
      debugPrint('Erro ao selecionar foto: $erro');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível acessar a câmera ou a galeria. Verifique as permissões do app.',
          ),
        ),
      );
    }
  }

  /// Remove a foto selecionada
  void _removerFoto() {
    setState(() => _fotoSelecionada = null);
  }

  /// Mostra opções de origem da foto
  void _mostrarOpcoesDeImagem() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Foto do Comprovante',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: const Text('Tirar Foto'),
                subtitle: Text(
                  'Usar a câmera do dispositivo',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _tirarFoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFFF57C00),
                  ),
                ),
                title: const Text('Escolher da Galeria'),
                subtitle: Text(
                  'Selecionar uma imagem existente',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _escolherDaGaleria();
                },
              ),
              if (_fotoSelecionada != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  title: const Text('Remover Foto'),
                  subtitle: Text(
                    'Excluir a foto selecionada',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removerFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Diesel')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
              const SizedBox(height: 24),

              // Seção de Foto do Comprovante
              _buildLabel('Foto do Comprovante (opcional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _mostrarOpcoesDeImagem,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fotoSelecionada != null
                          ? AppTheme.primary.withValues(alpha: 0.5)
                          : AppTheme.divider,
                      width: _fotoSelecionada != null ? 2 : 1,
                    ),
                  ),
                  child: _fotoSelecionada != null
                      ? _buildFotoPreview()
                      : _buildFotoPlaceholder(),
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
      ),
    );
  }

  /// Widget de placeholder quando nenhuma foto está selecionada
  Widget _buildFotoPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Toque para adicionar foto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Câmera ou Galeria',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  /// Widget de preview da foto selecionada
  Widget _buildFotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(
            _fotoSelecionada!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        // Gradiente sutil na parte inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        // Indicador de que há foto
        Positioned(
          bottom: 10,
          left: 14,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'Foto selecionada — toque para alterar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Botão de remover
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removerFoto,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
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

  Future<void> _adicionarVeiculo() async {
    final fazendaId = FazendaHelper.obterFazendaIdAtual(context);
    if (!FazendaHelper.validarFazendaAtiva(context, fazendaId)) return;

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo Veículo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nome do Veículo (Ex: Caminhão 1313)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = controller.text.trim();
              if (nome.isEmpty) return;

              try {
                await _service.adicionarVeiculo(fazendaId!, nome);
                if (!mounted) return;
                setState(() {
                  final jaExiste = _equipamentos.any(
                    (item) => item.toLowerCase() == nome.toLowerCase(),
                  );
                  if (!jaExiste) _equipamentos.add(nome);
                  _equipamentos.sort(
                    (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                  );
                  _equipamentoSelecionado = nome;
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on FirebaseException catch (erro) {
                debugPrint(
                  'Erro Firebase ao adicionar veiculo: '
                  '${erro.code} - ${erro.message}',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_mensagemErroVeiculo(erro))),
                );
              } catch (erro) {
                debugPrint('Erro ao adicionar veiculo: $erro');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nao foi possivel cadastrar o veiculo.'),
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _registrar() async {
    final fazendaId = FazendaHelper.obterFazendaIdAtual(context);
    if (!FazendaHelper.validarFazendaAtiva(context, fazendaId)) return;

    if (_equipamentoSelecionado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ou cadastre um veículo.')),
      );
      return;
    }

    final litros = double.tryParse(_litrosController.text);
    final horimetro = double.tryParse(_horimetroController.text);

    if (litros == null || horimetro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique os campos numéricos')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await _service.adicionarAbastecimento({
        'data': Timestamp.now(),
        'motorista': _nomeController.text.trim(),
        'litros': litros,
        'horimetro': horimetro,
        'aplicacao': _aplicacaoController.text.trim(),
        'equipamento': _equipamentoSelecionado,
        'usuario_uid': uid,
        'fazenda_id': fazendaId,
      }, fotoComprovante: _fotoSelecionada);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abastecimento salvo!'),
          backgroundColor: AppTheme.aprovada,
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (erro) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint(
        'Erro Firebase ao salvar abastecimento: ${erro.code} - ${erro.message}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mensagemErroFirebase(erro))));
    } catch (erro) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Erro ao salvar abastecimento: $erro');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar o abastecimento. Tente novamente.'),
        ),
      );
    }
  }

  String _mensagemErroFirebase(FirebaseException erro) {
    return AppErrorMessages.firebase(
      erro,
      fallback: 'Não foi possível salvar o abastecimento. Tente novamente.',
    );
  }

  String _mensagemErroVeiculo(
    FirebaseException erro, {
    bool carregando = false,
  }) {
    switch (erro.code) {
      case 'permission-denied':
        return carregando
            ? 'Você não tem permissão para consultar os veículos.'
            : 'Você não tem permissão para cadastrar veículos.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
      default:
        final acao = carregando ? 'carregar' : 'cadastrar';
        return 'Não foi possível $acao os veículos. Tente novamente.';
    }
  }
}
