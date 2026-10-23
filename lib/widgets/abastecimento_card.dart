import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/abastecimento.dart';
import 'package:intl/intl.dart';

class AbastecimentoCard extends StatelessWidget {
  final Abastecimento abastecimento;

  const AbastecimentoCard({super.key, required this.abastecimento});

  @override
  Widget build(BuildContext context) {
    final sdfDia = DateFormat('dd/MM/yyyy');
    final dataFormatada = abastecimento.data != null
        ? sdfDia.format(abastecimento.data!)
        : '--/--';

    final temFoto = abastecimento.temFotoComprovante;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _mostrarDetalhes(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.local_gas_station, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        abastecimento.equipamento,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${abastecimento.motorista} • $dataFormatada',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${abastecimento.litros.toStringAsFixed(1)} L',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (temFoto)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.photo_camera,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        Text(
                          'Hor: ${abastecimento.horimetro}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context) {
    final sdfDetalhes = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final temFoto = abastecimento.temFotoComprovante;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final tamanhoTela = MediaQuery.sizeOf(dialogContext);
        final largura = tamanhoTela.width > 568
            ? 520.0
            : tamanhoTela.width - 48;

        return Dialog(
          backgroundColor: AppTheme.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: largura,
            height: tamanhoTela.height * 0.82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detalhes do Abastecimento',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLinhaDetalhe(
                          Icons.calendar_today_outlined,
                          'Data',
                          abastecimento.data != null
                              ? sdfDetalhes.format(abastecimento.data!)
                              : '--',
                        ),
                        _buildLinhaDetalhe(
                          Icons.agriculture_outlined,
                          'Veículo',
                          abastecimento.equipamento,
                        ),
                        _buildLinhaDetalhe(
                          Icons.local_gas_station_outlined,
                          'Litros',
                          '${abastecimento.litros.toStringAsFixed(1)} L',
                        ),
                        _buildLinhaDetalhe(
                          Icons.person_outline,
                          'Motorista',
                          abastecimento.motorista,
                        ),
                        _buildLinhaDetalhe(
                          Icons.timer_outlined,
                          'Horímetro',
                          abastecimento.horimetro.toStringAsFixed(1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aplicação (Motivo)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            abastecimento.aplicacao.isEmpty
                                ? 'Não informado'
                                : abastecimento.aplicacao,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (temFoto) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                size: 19,
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Comprovante',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 240,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: () =>
                                    _mostrarFotoAmpliada(dialogContext),
                                child: _buildImagemComprovante(
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Toque na imagem para ampliar',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Este abastecimento não possui comprovante.',
                              style: TextStyle(color: AppTheme.textHint),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinhaDetalhe(IconData icone, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor.isEmpty ? 'Não informado' : valor,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe a foto em tela cheia
  void _mostrarFotoAmpliada(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Comprovante'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImagemComprovante(
                fit: BoxFit.contain,
                fundoEscuro: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagemComprovante({
    double? width,
    double? height,
    required BoxFit fit,
    bool fundoEscuro = false,
  }) {
    final temImagemRemota =
        (abastecimento.fotoComprovantePath?.isNotEmpty ?? false) ||
        (abastecimento.fotoComprovanteUrl?.isNotEmpty ?? false);

    if (temImagemRemota) {
      return FutureBuilder<String?>(
        future: _resolverUrlComprovante(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: width,
              height: height ?? 240,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final url = snapshot.data;
          if (snapshot.hasError || url == null || url.isEmpty) {
            return _buildErroImagem(fundoEscuro: fundoEscuro);
          }

          return Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, progresso) {
              if (progresso == null) return child;
              return SizedBox(
                width: width,
                height: height ?? 240,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildErroImagem(fundoEscuro: fundoEscuro),
          );
        },
      );
    }

    final base64 = abastecimento.fotoComprovanteBase64;
    if (base64 != null && base64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErroImagem(fundoEscuro: fundoEscuro),
        );
      } on FormatException {
        return _buildErroImagem(fundoEscuro: fundoEscuro);
      }
    }

    return _buildErroImagem(fundoEscuro: fundoEscuro);
  }

  Future<String?> _resolverUrlComprovante() async {
    final caminho = abastecimento.fotoComprovantePath?.trim();
    if (caminho != null && caminho.isNotEmpty) {
      try {
        return await FirebaseStorage.instance.ref(caminho).getDownloadURL();
      } on FirebaseException {
        // Registros antigos podem ter um caminho desatualizado, mas ainda
        // possuir uma URL de download valida no Firestore.
      }
    }

    final url = abastecimento.fotoComprovanteUrl?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  Widget _buildErroImagem({required bool fundoEscuro}) {
    final cor = fundoEscuro ? Colors.white70 : AppTheme.textHint;
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      color: fundoEscuro ? Colors.black : AppTheme.primarySurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: cor),
          const SizedBox(width: 8),
          Text('Erro ao carregar imagem', style: TextStyle(color: cor)),
        ],
      ),
    );
  }
}
