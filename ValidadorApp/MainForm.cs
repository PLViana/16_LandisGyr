using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using System.Reflection;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Xml.Linq;

namespace ValidadorApp;

public sealed class MainForm : Form
{
    private readonly WebView2 _wv = new() { Dock = DockStyle.Fill };

    private static readonly JsonSerializerOptions _jsonOpts = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = false,
    };

    public MainForm()
    {
        Text = "Landis+Gyr — Validador de Parâmetros XML";
        Size = new Size(1240, 800);
        MinimumSize = new Size(1000, 640);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(0, 66, 37);

        Controls.Add(_wv);
        Load += async (_, _) => await IniciarAsync();
    }

    // ─── Inicialização do WebView2 ────────────────────────────────────────────

    private async Task IniciarAsync()
    {
        try
        {
            var dataDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ValidadorLG", "WebView2");

            var env = await CoreWebView2Environment.CreateAsync(null, dataDir);
            await _wv.EnsureCoreWebView2Async(env);

            // Registra o handler de mensagens vindas do JavaScript
            _wv.CoreWebView2.WebMessageReceived += OnMensagemJS;

            // Carrega o HTML embutido no executável (EmbeddedResource)
            _wv.NavigateToString(CarregarHtml());
        }
        catch (Exception ex)
        {
            MostrarErro(
                "Falha ao inicializar o Microsoft Edge WebView2.\n\n" +
                $"Detalhe: {ex.Message}\n\n" +
                "Verifique se o WebView2 Runtime está instalado:\n" +
                "https://aka.ms/webview2");
        }
    }

    private static string CarregarHtml()
    {
        var asm = Assembly.GetExecutingAssembly();
        using var stream = asm.GetManifestResourceStream("ValidadorApp.validador.html")
            ?? throw new FileNotFoundException("Recurso 'validador.html' não encontrado no executável.");
        using var reader = new StreamReader(stream, Encoding.UTF8);
        return reader.ReadToEnd();
    }

    // ─── Bridge: recebe mensagem do JavaScript ────────────────────────────────

    private void OnMensagemJS(object? _, CoreWebView2WebMessageReceivedEventArgs e)
    {
        // Executa em background para não travar a UI
        Task.Run(() =>
        {
            try
            {
                var msg = JsonSerializer.Deserialize<MensagemJS>(e.WebMessageAsJson, _jsonOpts);
                if (msg is null || msg.Tipo != "comparar") return;

                if (string.IsNullOrWhiteSpace(msg.Padrao) || string.IsNullOrWhiteSpace(msg.Cliente))
                    throw new InvalidDataException("XML vazio recebido do frontend.");

                // ── Executa a lógica de comparação em C# ──
                var diffs = Comparar(msg.Padrao, msg.Cliente);
                var json  = JsonSerializer.Serialize(diffs, _jsonOpts);

                // Devolve o resultado para o JavaScript
                Invoke(() => _wv.CoreWebView2.ExecuteScriptAsync($"receberResultado({json})"));
            }
            catch (Exception ex)
            {
                var errMsg = JsonSerializer.Serialize(ex.Message);
                Invoke(() => _wv.CoreWebView2.ExecuteScriptAsync($"receberErro({errMsg})"));
            }
        });
    }

    // ─── Lógica de comparação XML (equivalente ao XmlComparer.cs) ────────────

    private static List<Diferenca> Comparar(string xmlPadrao, string xmlCliente)
    {
        var padrao  = XDocument.Parse(xmlPadrao);
        var cliente = XDocument.Parse(xmlCliente);
        var diffs   = new List<Diferenca>();

        if (padrao.Root is null || cliente.Root is null)
            throw new InvalidDataException("XML sem elemento <ROOT>.");

        // Monta dicionário COD → elemento do cliente
        var cDict = cliente.Root
            .Elements("VAR")
            .ToDictionary(x => x.Attribute("COD")?.Value ?? string.Empty, x => x);

        // Percorre todos os VARs do padrão
        foreach (var elP in padrao.Root.Elements("VAR"))
        {
            var cod = elP.Attribute("COD")?.Value ?? string.Empty;

            if (!cDict.TryGetValue(cod, out var elC))
            {
                diffs.Add(new Diferenca(cod, "PARAMETRO_AUSENTE", "EXISTE", "NAO ENCONTRADO"));
                continue;
            }

            // Verifica divergência no atributo VL (label/nome do parâmetro)
            var vlP = elP.Attribute("VL")?.Value ?? string.Empty;
            var vlC = elC.Attribute("VL")?.Value ?? string.Empty;
            if (vlP != vlC)
                diffs.Add(new Diferenca(cod, "VL", vlP, vlC));

            // Verifica divergência no atributo IX (valor hexadecimal)
            var ixP = elP.Attribute("IX")?.Value ?? string.Empty;
            var ixC = elC.Attribute("IX")?.Value ?? string.Empty;
            if (ixP != ixC)
                diffs.Add(new Diferenca(cod, "IX", ixP, ixC));
        }

        // Detecta parâmetros presentes no cliente mas ausentes no padrão
        var pCods = padrao.Root
            .Elements("VAR")
            .Select(x => x.Attribute("COD")?.Value ?? string.Empty)
            .ToHashSet();

        foreach (var elC in cliente.Root.Elements("VAR"))
        {
            var cod = elC.Attribute("COD")?.Value ?? string.Empty;
            if (!pCods.Contains(cod))
                diffs.Add(new Diferenca(cod, "PARAMETRO_EXTRA", "NAO EXISTE", "EXISTE"));
        }

        return diffs;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static void MostrarErro(string mensagem)
        => MessageBox.Show(mensagem, "Erro — Validador XML",
            MessageBoxButtons.OK, MessageBoxIcon.Error);

    // ─── DTOs ─────────────────────────────────────────────────────────────────

    private sealed record MensagemJS(
        [property: JsonPropertyName("tipo")]    string? Tipo,
        [property: JsonPropertyName("padrao")]  string? Padrao,
        [property: JsonPropertyName("cliente")] string? Cliente);

    private sealed record Diferenca(
        string Cod,
        string CampoDivergente,
        string Esperado,
        string Encontrado);
}
