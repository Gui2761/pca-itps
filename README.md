# PCA 2027 — Sistema de Planejamento de Contratações Anual

Este é um repositório isolado e independente contendo o **Sistema PCA 2027**, desenvolvido exclusivamente para ambiente **Windows Desktop** com backend integrado à intranet do ITPS.

---

## 🏛️ Estrutura do Projeto

*   **`app/`**: Aplicativo desktop em **Flutter Windows Desktop** implementando o **Antigravity Kit** (visual Glassmorphism premium, dark mode, tipografia Outfit/Inter).
*   **`backend/`**: Microsserviço de suporte desenvolvido em **Python (FastAPI)** com endpoints de CRUD completo integrados à base PostgreSQL central (`bd_intranet` no IP `172.23.6.109`) no schema `pca`.

---

## 🚀 Como Executar

### 1. Backend (FastAPI)
1. Certifique-se de que o Python e os pacotes necessários estejam instalados.
2. Inicie o servidor:
   ```bash
   cd backend
   python -m venv venv
   # Ative o ambiente virtual
   # no Windows:
   .\venv\Scripts\activate
   # Instale as dependências
   pip install -r requirements.txt
   # Inicie
   python main.py
   ```

### 2. Aplicativo Desktop (Flutter)
1. Instale o Flutter SDK em sua máquina de desenvolvimento.
2. Execute o aplicativo nativo para Windows:
   ```bash
   cd app
   flutter pub get
   flutter run -d windows
   ```
