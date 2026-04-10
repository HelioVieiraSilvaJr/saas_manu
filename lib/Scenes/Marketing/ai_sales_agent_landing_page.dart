import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

class AiSalesAgentLandingPage extends StatefulWidget {
  const AiSalesAgentLandingPage({super.key});

  @override
  State<AiSalesAgentLandingPage> createState() =>
      _AiSalesAgentLandingPageState();
}

class _AiSalesAgentLandingPageState extends State<AiSalesAgentLandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _abilitiesKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1180;
    final horizontalPadding = width >= 1440
        ? 80.0
        : width >= 1000
        ? 48.0
        : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      body: Stack(
        children: [
          const Positioned.fill(child: _NebulaBackground()),
          Positioned.fill(
            child: CustomPaint(
              painter: _TechGridPainter(
                lineColor: colors.blueLight.withValues(alpha: 0.10),
                dotColor: colors.secundaryLight.withValues(alpha: 0.14),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      0,
                    ),
                    child: _buildTopBar(isDesktop),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _Reveal(
                            delayMs: 40,
                            child: _buildHeroSection(
                              isDesktop: isDesktop,
                              textStyles: textStyles,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _Reveal(
                            delayMs: 120,
                            child: _buildMetricsBand(colors, textStyles),
                          ),
                          const SizedBox(height: 34),
                          _Reveal(
                            delayMs: 180,
                            child: _buildLogosBand(colors, textStyles),
                          ),
                          const SizedBox(height: 44),
                          _Reveal(
                            delayMs: 240,
                            child: _buildFeaturesSection(colors, textStyles),
                          ),
                          const SizedBox(height: 44),
                          _Reveal(
                            delayMs: 320,
                            child: _buildAbilitiesSection(colors, textStyles),
                          ),
                          const SizedBox(height: 44),
                          _Reveal(
                            delayMs: 400,
                            child: _buildFlowSection(colors, textStyles),
                          ),
                          const SizedBox(height: 44),
                          _Reveal(
                            delayMs: 480,
                            child: _buildAudienceSection(colors, textStyles),
                          ),
                          const SizedBox(height: 44),
                          _Reveal(
                            delayMs: 560,
                            child: _buildFinalCta(colors, textStyles),
                          ),
                          const SizedBox(height: 32),
                          _buildFooter(colors, textStyles),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.secundaryLight, colors.blue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.secundaryLight.withValues(alpha: 0.28),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Sales Engine',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'WhatsApp + CRM + Agente de IA',
                style: textStyles.labelMedium.copyWith(
                  color: colors.greyLighter,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isDesktop) ...[
            _TopNavLink(
              label: 'Recursos',
              onTap: () => _scrollTo(_featuresKey),
            ),
            _TopNavLink(
              label: 'Poderes da IA',
              onTap: () => _scrollTo(_abilitiesKey),
            ),
            _TopNavLink(label: 'Demonstração', onTap: () => _scrollTo(_ctaKey)),
            const SizedBox(width: 10),
          ],
          OutlinedButton(
            onPressed: () => _scrollTo(_ctaKey),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: colors.blueLight.withValues(alpha: 0.36)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Agendar demo'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _goToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.secundaryLight,
              foregroundColor: colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required bool isDesktop,
    required DSTextStyle textStyles,
    required DSColors colors,
  }) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.secundaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.secundaryLight.withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            'ATENDIMENTO COMERCIAL COM IA OPERACIONAL',
            style: textStyles.overline.copyWith(
              color: colors.secundaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Transforme seu WhatsApp em um canal de vendas com inteligência artificial real.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isDesktop ? 64 : 40,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -2.0,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Atenda clientes, consulte produtos reais, monte carrinhos, registre vendas, informe status do pedido e recupere oportunidades perdidas com um agente de IA conectado ao CRM da sua operação.',
            style: textStyles.bodyLarge.copyWith(
              color: const Color(0xFFC5D1DE),
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => _scrollTo(_ctaKey),
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Quero uma demonstração'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.highlights,
                foregroundColor: colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                textStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _scrollTo(_featuresKey),
              icon: const Icon(Icons.memory_rounded),
              label: const Text('Ver recursos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: colors.blueLight.withValues(alpha: 0.36),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SignalPill(label: 'Texto + audio'),
            _SignalPill(label: 'CRM integrado'),
            _SignalPill(label: 'Carrinho e vendas'),
            _SignalPill(label: 'Follow-up automático'),
          ],
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 28),
          _buildVisualConsole(colors),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: title),
        const SizedBox(width: 28),
        Expanded(flex: 5, child: _buildVisualConsole(colors)),
      ],
    );
  }

  Widget _buildVisualConsole(DSColors colors) {
    return SizedBox(
      height: 620,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 30,
            left: 30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.secundaryLight.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 50,
            child: Transform.rotate(
              angle: -0.06,
              child: _GlassPanel(
                width: 390,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statusDot(const Color(0xFFF97316)),
                        const SizedBox(width: 6),
                        _statusDot(const Color(0xFF22C55E)),
                        const SizedBox(width: 6),
                        _statusDot(const Color(0xFF38BDF8)),
                        const Spacer(),
                        Text(
                          'CONVERSATION ENGINE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _conversationBubble(
                      alignEnd: false,
                      title: 'Cliente',
                      body: 'Oi, vocês têm vestido midi floral no tamanho M?',
                      color: const Color(0xFF0F2034),
                    ),
                    const SizedBox(height: 12),
                    _conversationBubble(
                      alignEnd: true,
                      title: 'Agente IA',
                      body:
                          'Acabei de consultar o catálogo. Tenho 2 opções em M e uma alternativa semelhante em azul. Quer que eu te mostre as melhores?',
                      color: colors.secundaryColor.withValues(alpha: 0.16),
                      border: colors.secundaryLight.withValues(alpha: 0.30),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A2B),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.blueLight.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _miniMetric(
                                'Tempo de resposta',
                                '< 15s',
                                colors.secundaryLight,
                              ),
                              const SizedBox(width: 12),
                              _miniMetric(
                                'Ações do agente',
                                '7 tools',
                                colors.highlights,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _PipelineStep(
                                  icon: Icons.forum_rounded,
                                  label: 'Atende',
                                ),
                              ),
                              Expanded(
                                child: _PipelineStep(
                                  icon: Icons.shopping_cart_checkout_rounded,
                                  label: 'Opera',
                                ),
                              ),
                              Expanded(
                                child: _PipelineStep(
                                  icon: Icons.auto_graph_rounded,
                                  label: 'Converte',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 70,
            child: Transform.rotate(
              angle: 0.05,
              child: _GlassPanel(
                width: 290,
                padding: const EdgeInsets.all(18),
                borderColor: colors.highlights.withValues(alpha: 0.20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAINEL OPERACIONAL',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.highlights,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OperationalPulseCard(
                      title: 'Carrinhos em risco',
                      value: '18',
                      subtitle: 'Clientes sem resposta há 2h',
                      accent: colors.highlights,
                    ),
                    const SizedBox(height: 12),
                    _OperationalPulseCard(
                      title: 'Pedidos em trânsito',
                      value: '42',
                      subtitle: 'Atualizações automatizadas',
                      accent: colors.secundaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBand(DSColors colors, DSTextStyle textStyles) {
    final items = [
      ('24/7', 'Atendimento comercial sempre disponível'),
      ('CRM', 'Cadastro, carrinho, venda e contexto na mesma operação'),
      ('IA + Ação', 'O agente conversa e executa tarefas reais'),
      ('Pós-venda', 'Cliente informado sobre o status do pedido'),
    ];

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: items
            .map(
              (item) => SizedBox(
                width: 250,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.blueLight.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: textStyles.bodyMedium.copyWith(
                          color: const Color(0xFFBED0E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLogosBand(DSColors colors, DSTextStyle textStyles) {
    final labels = [
      'WhatsApp',
      'OpenAI',
      'Evolution API',
      'n8n',
      'Firestore',
      'CRM',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.blueLight.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                label,
                style: textStyles.labelLarge.copyWith(
                  color: const Color(0xFFDFE9F4),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeaturesSection(DSColors colors, DSTextStyle textStyles) {
    final features = [
      (
        Icons.chat_bubble_outline_rounded,
        'Atendimento por texto e áudio',
        'O agente recebe mensagens, interpreta intenção e responde com contexto comercial.',
      ),
      (
        Icons.inventory_2_outlined,
        'Consulta de produtos reais',
        'Busca catálogo, preço, disponibilidade e alternativas sem inventar informações.',
      ),
      (
        Icons.shopping_cart_checkout_rounded,
        'Carrinho operado na conversa',
        'Adiciona, remove e atualiza itens enquanto conduz o cliente para o fechamento.',
      ),
      (
        Icons.receipt_long_rounded,
        'Registro de venda no CRM',
        'Transforma o carrinho atual em uma venda registrada e rastreável.',
      ),
      (
        Icons.local_shipping_outlined,
        'Atualização automática do pedido',
        'Informa ao cliente quando o status do pedido muda.',
      ),
      (
        Icons.refresh_rounded,
        'Recuperação de carrinho abandonado',
        'Retoma conversas paradas e tenta resgatar vendas perdidas.',
      ),
    ];

    return Column(
      key: _featuresKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'RECURSOS QUE GERAM VALOR',
          title:
              'Tudo o que a plataforma já faz hoje para acelerar vendas e organizar a operação.',
          subtitle:
              'A proposta não é automatizar respostas soltas. É integrar comunicação, CRM e execução em um mesmo fluxo.',
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: features
              .map(
                (feature) => _FeatureCard(
                  icon: feature.$1,
                  title: feature.$2,
                  description: feature.$3,
                  colors: colors,
                  textStyles: textStyles,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAbilitiesSection(DSColors colors, DSTextStyle textStyles) {
    final abilities = [
      'Atende como vendedor digital com foco em conversão.',
      'Entende áudio e texto no mesmo canal.',
      'Atualiza cadastro do cliente durante a conversa.',
      'Sugere alternativas de produto com base no catálogo.',
      'Opera ferramentas do CRM para carrinho, venda e acompanhamento.',
      'Escala humanos com contexto preservado quando necessário.',
    ];

    return Column(
      key: _abilitiesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'PODERES DO AGENTE DE IA',
          title:
              'Um agente que não só conversa. Ele consulta, decide e executa.',
          subtitle:
              'O valor da inteligência artificial aqui está na capacidade de agir sobre a operação real da empresa, com regras, contexto e rastreabilidade.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth > 980;
            final left = _GlassPanel(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI CAPABILITY MATRIX',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.secundaryLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...abilities.map(
                    (ability) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: colors.secundaryLight.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: colors.secundaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ability,
                              style: textStyles.bodyLarge.copyWith(
                                color: const Color(0xFFDEEBF8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            final right = _GlassPanel(
              padding: const EdgeInsets.all(22),
              borderColor: colors.highlights.withValues(alpha: 0.18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O que isso significa na prática',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sua empresa ganha um vendedor digital treinado para atender rápido, vender com contexto e não se perder entre mensagens, carrinhos, pedidos e pendências.',
                    style: textStyles.bodyLarge.copyWith(
                      color: const Color(0xFFBFD0E0),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _SignalPill(label: 'Pré-venda'),
                      _SignalPill(label: 'Venda'),
                      _SignalPill(label: 'Pós-venda'),
                      _SignalPill(label: 'Handoff humano'),
                    ],
                  ),
                ],
              ),
            );

            if (!useRow) {
              return Column(
                children: [left, const SizedBox(height: 18), right],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 18),
                Expanded(child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFlowSection(DSColors colors, DSTextStyle textStyles) {
    final steps = [
      (
        'Cliente chama no WhatsApp',
        'Texto ou áudio entram no fluxo automaticamente.',
      ),
      (
        'IA interpreta e consulta contexto',
        'A conversa ganha dados do cliente, da loja e do catálogo.',
      ),
      (
        'Agente executa ações reais',
        'Atualiza cliente, opera carrinho, registra venda e gera follow-up.',
      ),
      (
        'Operação fica mais inteligente',
        'O negócio passa a acompanhar pedidos, pendências e oportunidades com muito mais controle.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'FLUXO DE ALTO IMPACTO',
          title: 'Da conversa à conversão em uma trilha operacional conectada.',
          subtitle:
              'Cada etapa foi desenhada para reduzir atrito, acelerar resposta e manter contexto do começo ao fim.',
        ),
        const SizedBox(height: 22),
        _GlassPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == steps.length - 1 ? 0 : 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.secundaryLight, colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (index != steps.length - 1)
                          Container(
                            width: 2,
                            height: 48,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: colors.blueLight.withValues(alpha: 0.18),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.$1,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.$2,
                              style: textStyles.bodyLarge.copyWith(
                                color: const Color(0xFFBFD0E0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceSection(DSColors colors, DSTextStyle textStyles) {
    final cards = [
      (
        'Quem vende no WhatsApp',
        'Ideal para operações que já recebem demanda por mensagens e precisam converter melhor.',
      ),
      (
        'Quem perde vendas por demora',
        'A plataforma reduz o silêncio operacional que mata oportunidades.',
      ),
      (
        'Quem quer escalar sem caos',
        'A IA absorve volume, enquanto o time humano foca no que realmente exige intervenção.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'PARA QUEM ESSA TECNOLOGIA É PERFEITA',
          title:
              'Negócios que precisam crescer sem depender de atendimento artesanal.',
          subtitle:
              'Especialmente valiosa para operações que querem vender mais no WhatsApp com mais velocidade, consistência e controle.',
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: cards
              .map(
                (card) => _AudienceCard(
                  title: card.$1,
                  description: card.$2,
                  colors: colors,
                  textStyles: textStyles,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFinalCta(DSColors colors, DSTextStyle textStyles) {
    return Container(
      key: _ctaKey,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF102A45),
            const Color(0xFF0D5D76),
            colors.secundaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.secundaryLight.withValues(alpha: 0.14),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRONTO PARA VENDER COM MAIS INTELIGÊNCIA?',
            style: textStyles.overline.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Coloque um agente de IA para atender, vender e organizar a sua operação no WhatsApp.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Se o seu negócio já recebe demanda no WhatsApp, a próxima evolução é transformar conversa em processo comercial com contexto, velocidade e controle.',
            style: textStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _goToLogin,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Quero ver funcionando'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _scrollTo(_featuresKey),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Revisar recursos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(DSColors colors, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AI Sales Engine • WhatsApp + CRM + Automação comercial com IA',
              style: textStyles.bodySmall.copyWith(
                color: const Color(0xFF89A0B7),
              ),
            ),
          ),
          TextButton(
            onPressed: _goToLogin,
            child: const Text('Entrar na plataforma'),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _miniMetric(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationBubble({
    required bool alignEnd,
    required String title,
    required String body,
    required Color color,
    Color? border,
  }) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: border ?? Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: textStyles.overline.copyWith(
            color: colors.secundaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.08,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            subtitle,
            style: textStyles.bodyLarge.copyWith(
              color: const Color(0xFFB7CADD),
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
    required this.textStyles,
  });

  final IconData icon;
  final String title;
  final String description;
  final DSColors colors;
  final DSTextStyle textStyles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: _GlassPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.secundaryLight.withValues(alpha: 0.90),
                    colors.blue.withValues(alpha: 0.90),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: textStyles.bodyLarge.copyWith(
                color: const Color(0xFFBFD0E0),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.title,
    required this.description,
    required this.colors,
    required this.textStyles,
  });

  final String title;
  final String description;
  final DSColors colors;
  final DSTextStyle textStyles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.blueLight.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: textStyles.bodyLarge.copyWith(
                color: const Color(0xFFBFD0E0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationalPulseCard extends StatelessWidget {
  const _OperationalPulseCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.radar_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TopNavLink extends StatelessWidget {
  const _TopNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2DD4BF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: borderColor ?? colors.blueLight.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, required this.delayMs});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700 + delayMs),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, widgetChild) {
        final normalized = ((value * 1.15) - (delayMs / 1200)).clamp(0.0, 1.0);
        return Opacity(
          opacity: normalized,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - normalized)),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _NebulaBackground extends StatelessWidget {
  const _NebulaBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _Orb(
          alignment: Alignment(-0.92, -0.88),
          size: 340,
          colors: [Color(0x552DD4BF), Color(0x002DD4BF)],
        ),
        _Orb(
          alignment: Alignment(0.96, -0.60),
          size: 420,
          colors: [Color(0x5538BDF8), Color(0x0038BDF8)],
        ),
        _Orb(
          alignment: Alignment(-0.15, 0.88),
          size: 480,
          colors: [Color(0x44F59E0B), Color(0x00F59E0B)],
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _TechGridPainter extends CustomPainter {
  _TechGridPainter({required this.lineColor, required this.dotColor});

  final Color lineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = dotColor;
    const gap = 44.0;

    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 0; x <= size.width; x += gap * 2) {
      for (double y = 0; y <= size.height; y += gap * 2) {
        canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
      }
    }

    final pulsePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [dotColor.withValues(alpha: 0.30), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.28),
              radius: 180,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      180,
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TechGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.dotColor != dotColor;
  }
}
