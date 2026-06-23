# 🐮 Farm Management (Gestão Rural)

## 📝 Descrição do Sistema
O **Farm Management** é um aplicativo multiplataforma criado com **Flutter** para digitalizar e otimizar a administração de fazendas de gado leiteiro.  
Ele substitui anotações manuais e descentralizadas, permitindo que **Gestores** e **Funcionários** registrem informações essenciais em tempo real.

O sistema centraliza:

- Controle do rebanho  
- Produção de leite  
- Abastecimento de maquinário  
- Gestão de folgas  
- Relatórios financeiros automáticos  
- Notificações em tempo real  

---

## 🚀 Funcionalidades Principais

### 🔐 Autenticação por Perfil
- Login seguro com perfis de **Gestor** e **Funcionário**.
- Cadastro de novos usuários com seleção de função.
- Tela inicial de seleção de perfil (Role Selection).

### 🐄 Gestão de Animais
- Cadastro de nascimentos com foto via câmera/galeria.
- Listagem filtrada (mês ou número do brinco).
- Edição de dados de animais existentes.

### 🥛 Controle de Produção Leiteira
- Registro diário da litragem por tanque.
- Cálculo total automático.

### ⛽ Controle de Diesel
- Registro de abastecimentos.
- Horímetro.
- Identificação de motorista e maquinário.
- Histórico completo de abastecimentos.

### 🧑‍🌾 Gestão de RH – Folgas
**Funcionário**  
- Solicitação de folga e visualização via calendário interativo.
- Histórico de solicitações com status (aprovada / pendente / reprovada).

**Gestor**  
- Aprovação/Reprovação de solicitações pendentes.
- Badge com contador de pendências no painel.
- Notificações em tempo real para novas solicitações.

### 📊 Relatórios Financeiros
- Faturamento mensal consolidado.  
- Média diária automática.  
- Preço do leite configurável.

---

## 🛠 Tecnologias Utilizadas

### 📱 Mobile (Flutter — Multiplataforma)
- **Dart 3.10+ & Flutter**: Framework de UI multiplataforma com compilação nativa para Android, iOS, Web, Windows, Linux e macOS.
- **Provider**: Gerenciamento de estado reativo com `ChangeNotifierProvider` e `MultiProvider` para separação clara de domínios (Auth, Animal, Produção, Abastecimento, Folga).
- **Google Fonts (Inter)**: Tipografia moderna e consistente em todas as telas.
- **Material Design 3**: Componentes visuais modernos com `useMaterial3: true`, incluindo gradientes, cards com bordas arredondadas e tema customizado.
- **image_picker**: Captura de fotos via câmera ou galeria para registro de animais.

### ☁️ Back-end (Serverless)
- **Firebase Core**: Inicialização e configuração do ambiente Firebase.
- **Cloud Firestore**: Banco de dados NoSQL em tempo real para persistência de dados.
- **Firebase Authentication**: Autenticação segura de usuários com controle de perfis.

### 🧰 Ferramentas
- **Flutter SDK ^3.10.8**: Versão estável com suporte a Dart 3 e null safety completo.
- **intl & flutter_localizations**: Internacionalização e formatação de datas em Português Brasileiro (`pt_BR`).
- **analysis_options.yaml**: Regras de lint configuradas com `flutter_lints` para qualidade de código.

---

## 🏗 Arquitetura do Projeto

O projeto segue uma **arquitetura em camadas** inspirada no padrão **MVVM**, com separação clara entre dados, lógica de estado e interface:

```
┌──────────────────────────────────┐
│         UI (Screens/Widgets)     │   ← Apresentação visual
├──────────────────────────────────┤
│         Providers (State)        │   ← Gerenciamento de estado (ViewModel)
├──────────────────────────────────┤
│         Services (Data Layer)    │   ← Acesso a dados (Firebase/Firestore)
├──────────────────────────────────┤
│         Models (Domain)          │   ← Entidades do domínio
└──────────────────────────────────┘
```

---

## 📂 Estrutura de Diretórios

```text
app_gestao_fazenda/
├── pubspec.yaml                  # Dependências do projeto (Firebase, Provider, Google Fonts, etc.)
├── analysis_options.yaml         # Regras de lint e qualidade de código
├── android/                      # Configurações nativas Android (Gradle, Manifest, google-services.json)
├── ios/                          # Configurações nativas iOS
├── web/                          # Configurações para build Web
├── windows/                      # Configurações para build Windows
├── linux/                        # Configurações para build Linux
├── macos/                        # Configurações para build macOS
├── test/                         # Testes unitários e de widgets
└── lib/                          # CÓDIGO-FONTE PRINCIPAL
    ├── main.dart                 # Ponto de entrada: inicializa Firebase, Providers e rotas
    ├── core/                     # NÚCLEO DA APLICAÇÃO
    │   ├── app_theme.dart        # Design System: cores, gradientes, tipografia e tema Material 3
    │   └── app_routes.dart       # Rotas nomeadas para navegação entre telas
    ├── data/                     # CAMADA DE DADOS
    │   ├── models/               # Classes de domínio (entidades do negócio)
    │   │   ├── animal.dart       # Modelo de Animal (brinco, raça, data de nascimento, foto)
    │   │   ├── producao_leite.dart # Modelo de Produção de Leite (litragem, tanque, data)
    │   │   ├── abastecimento.dart # Modelo de Abastecimento de Diesel (litros, horímetro, motorista)
    │   │   ├── usuario.dart      # Modelo de Usuário (nome, email, função gestor/funcionário)
    │   │   ├── solicitacao.dart  # Modelo de Solicitação de Folga
    │   │   ├── historico_folga.dart # Modelo de Histórico de Folga
    │   │   └── folga_status.dart # Enum de Status de Folga (aprovada, pendente, reprovada)
    │   └── services/             # Serviços de acesso a dados (comunicação com Firebase)
    │       ├── auth_service.dart           # Login, registro e gerenciamento de sessão
    │       ├── animal_service.dart         # CRUD de animais no Firestore
    │       ├── producao_leite_service.dart # Registro e consulta de produção leiteira
    │       ├── abastecimento_service.dart  # Registro de abastecimentos de diesel
    │       ├── folga_service.dart          # Solicitação e aprovação de folgas
    │       ├── notificacao_service.dart    # Notificações em tempo real (badge, marcar como lida)
    │       └── configuracao_service.dart   # Configurações globais (preço do leite, etc.)
    ├── providers/                # CAMADA DE ESTADO (ViewModel)
    │   ├── auth_provider.dart          # Estado de autenticação e usuário logado
    │   ├── animal_provider.dart        # Estado da lista de animais e filtros
    │   ├── producao_provider.dart      # Estado da produção de leite
    │   ├── abastecimento_provider.dart # Estado dos abastecimentos de diesel
    │   └── folga_provider.dart         # Estado das solicitações de folga
    ├── screens/                  # TELAS DA APLICAÇÃO
    │   ├── role_selection_screen.dart         # Seleção de perfil (Gestor ou Funcionário)
    │   ├── login_screen.dart                  # Tela de Login
    │   ├── register_screen.dart               # Tela de Cadastro
    │   ├── gestor_dashboard_screen.dart       # Painel do Gestor (6 cards de funcionalidades)
    │   ├── funcionario_dashboard_screen.dart  # Painel do Funcionário (4 cards de funcionalidades)
    │   ├── registrar_producao_screen.dart     # Registro de produção de leite
    │   ├── relatorio_mensal_screen.dart       # Relatório financeiro mensal
    │   ├── lista_animais_screen.dart          # Listagem de animais com filtros
    │   ├── registrar_nascimento_screen.dart   # Cadastro/edição de animais
    │   ├── controle_diesel_screen.dart        # Registro de abastecimentos
    │   ├── historico_abastecimentos_screen.dart # Histórico de abastecimentos
    │   ├── controle_folgas_screen.dart        # Calendário de folgas (funcionário)
    │   ├── solicitacoes_pendentes_screen.dart # Aprovação de folgas (gestor)
    │   └── historico_solicitacoes_screen.dart # Histórico de solicitações
    └── widgets/                  # COMPONENTES REUTILIZÁVEIS
        ├── farm_card.dart        # Card de navegação com gradiente e ícone (usado nos dashboards)
        ├── abastecimento_card.dart # Card de exibição de abastecimento
        ├── animal_list_tile.dart  # Tile de exibição de animal na lista
        ├── calendar_grid.dart    # Grid de calendário para visualização de folgas
        ├── loading_button.dart   # Botão com indicador de carregamento
        └── solicitacao_card.dart # Card de exibição de solicitação de folga
```

---

## 🌿 Estrutura de Branches

- **main** → versão estável do app integrada com Firebase  
- **feature/*** → desenvolvimento de novas funcionalidades  
  - Exemplo:  
    - `feature/controle-vacinas`  
    - `feature/graficos`

> 💡 **Atenção:** O arquivo `google-services.json` deve estar na pasta `/android/app`.

---

## 🚀 Instruções de Execução

### ✔️ Pré-requisitos
- **Flutter SDK** ^3.10.8 instalado e configurado  
- **Android Studio** Ladybug ou superior (ou VS Code com extensões Flutter)  
- **JDK 11+**  
- Conta no **Firebase** (opcional para novo ambiente)  
- Emulador Android ou dispositivo físico conectado  

---

### 1️⃣ Clonar o Repositório

```bash
git clone https://github.com/ricardoissadesousa/app-gestao-fazenda.git
cd app_gestao_fazenda
```

### 2️⃣ Instalar Dependências

```bash
flutter pub get
```

### 3️⃣ Configurar o Firebase

O projeto já possui um `google-services.json` configurado para:

```
package: com.example.app_gestao_fazenda
```

Apenas garanta que o dispositivo/emulador tenha acesso à internet.

### 4️⃣ Executar o Projeto

```bash
flutter run
```

Ou via Android Studio:  
1. Abrir o Android Studio  
2. Ir em **Open** e selecionar a pasta do projeto  
3. Aguardar o **Flutter Pub Get** automático  
4. Selecionar o emulador ou dispositivo físico  
5. Clicar em **Run** (▶️)

---

## 📱 Telas do Aplicativo

| Tela | Descrição |
|------|-----------|
| **Seleção de Perfil** | Escolha entre Gestor e Funcionário |
| **Login** | Autenticação segura via Firebase Auth |
| **Cadastro** | Registro de novos usuários com função |
| **Painel do Gestor** | Dashboard com 6 funcionalidades (Produção, Relatórios, Animais, Nascimentos, Folgas, Diesel) |
| **Painel do Funcionário** | Dashboard com 4 funcionalidades (Folgas, Diesel, Nascimentos, Produção) |
| **Produção de Leite** | Registro diário por tanque |
| **Relatório Mensal** | Faturamento e médias automáticas |
| **Lista de Animais** | Filtros por mês e brinco |
| **Registrar Nascimento** | Cadastro com foto |
| **Controle de Diesel** | Abastecimentos com horímetro |
| **Controle de Folgas** | Calendário interativo + solicitação |
| **Solicitações Pendentes** | Aprovação/reprovação (gestor) |

---

## 👥 Contribuições da Equipe

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/ricardoissadesousa">
        <img src="https://github.com/ricardoissadesousa.png" width="100px;" alt="Foto do Ricardo"/><br>
        <sub>
          <p>Ricardo</p>
          <b>Função: Back-End, Banco de Dados, Front-End</b>
        </sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Marllonlp">
        <img src="https://avatars.githubusercontent.com/u/143544599?v=4" width="100px;" alt="Foto do Marlon"/><br>
        <sub>
          <p>Marlon</p>
          <b>Função: Back-End, Banco de Dados, Front-End</b>
        </sub>
      </a>
    </td>
  </tr>
</table>

---

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos e de aprendizado.
