# Landis+Gyr — Validador de Parâmetros XML

Ferramenta para comparar o XML de configuração de um medidor E650 G2 com um XML padrão (gabarito), identificando parâmetros ausentes, extras ou com valores divergentes.

---

## Uso rápido (sem instalação)

Dê duplo clique em **`abrir.bat`** — abre o validador direto no navegador. Não precisa instalar nada.

1. Arraste o **XML Padrão** (gabarito) na zona da esquerda
2. Arraste o **XML Cliente** (medidor) na zona da direita
3. Clique em **Comparar Arquivos**
4. Exporte o resultado em JSON ou CSV se necessário

---

## Uso como executável (.exe)

Para gerar um `.exe` standalone com a engine de comparação em C#:

1. Dê duplo clique em **`install.bat`**
2. Se o .NET SDK não estiver instalado, o próprio bat faz o download e instala automaticamente (sem permissão de administrador, requer internet)
3. Ao final, um atalho **"Validador XML LG"** é criado na Área de Trabalho

O executável gerado fica em:
```
%APPDATA%\ValidadorLG\ValidadorXML.exe
```

---

## Tipos de divergência detectados

| Tipo | Descrição |
|---|---|
| `PARAMETRO_AUSENTE` | Parâmetro existe no padrão mas não foi encontrado no cliente |
| `PARAMETRO_EXTRA` | Parâmetro existe no cliente mas não consta no padrão |
| `VL` | Valor do atributo VL (label/nome) diferente entre os dois arquivos |
| `IX` | Valor do atributo IX (valor hexadecimal) diferente entre os dois arquivos |

---

## Estrutura do projeto

```
16_LandisGyr/
├── abrir.bat                  # Abre o validador no navegador (uso imediato)
├── install.bat                # Compila e instala o .exe (requer internet na 1a vez)
├── global.json                # Versão do .NET SDK exigida (10.0.x)
├── validador.html             # Interface web standalone
│
├── ValidadorApp/              # Projeto C# WinForms + WebView2
│   ├── ValidadorApp.csproj
│   ├── Program.cs
│   ├── MainForm.cs            # Engine de comparação + bridge JavaScript↔C#
│   └── validador.html         # HTML embutido no executável como recurso
│
└── CheckListValidator/        # Projeto C# original (CLI + exportação nativa)
    ├── Program.cs
    ├── LibExports.cs          # Exporta ValidarXmlMedidor via UnmanagedCallersOnly
    ├── models/Diferenca.cs
    └── services/
        ├── ChecklistValidato.cs
        └── XmlComparer.cs
```

---

## Requisitos

### Uso via navegador (`abrir.bat`)
- Nenhum — funciona em qualquer Windows com Edge, Chrome ou Firefox

### Uso como `.exe` (`install.bat`)
- Windows 10 ou 11
- Microsoft Edge WebView2 Runtime (já vem instalado com o Windows 10/11 e Edge)
- .NET 10 SDK — instalado automaticamente pelo `install.bat` se necessário

---

## Como funciona a integração HTML + C#

Quando rodando como `.exe`, o HTML envia os XMLs para o C# processar via ponte WebView2:

```
HTML (drag & drop) → window.chrome.webview.postMessage({ tipo:'comparar', ... })
        ↓
C# MainForm.cs → XDocument.Parse() → XmlComparer → List<Diferenca>
        ↓
JavaScript receberResultado(diffs) → renderiza tabela de resultados
```

Quando aberto direto no navegador, a comparação é feita pela reimplementação equivalente em JavaScript embutida no próprio HTML.
