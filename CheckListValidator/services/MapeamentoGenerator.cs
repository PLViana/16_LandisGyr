using System.Text.Json;
using System.Xml.Linq;

namespace ChecklistValidator.services;

public class MapeamentoGenerator
{
    public void Gerar(string caminhoPdf, string caminhoXml)
    {
        PdfConverter pdf = new();

        var parametrosPdf = pdf.LerParametros(caminhoPdf);
        var xml = XDocument.Load(caminhoXml);

        var codsXml = xml.Root!
            .Elements("VAR")
            .Select(x => x.Attribute("COD")?.Value ?? "")
            .Where(x => x != "")
            .ToList();

        var sugestoes = parametrosPdf.Keys.Select(campoPdf => new
        {
            CampoPdf = campoPdf,
            CodXml = EncontrarMelhorCod(campoPdf, codsXml),
            Valores = new Dictionary<string, string>()
        }).ToList();

        string json = JsonSerializer.Serialize(
            sugestoes,
            new JsonSerializerOptions { WriteIndented = true }
        );

        File.WriteAllText("mapeamento-gerado.json", json);

        Console.WriteLine("Arquivo mapeamento-gerado.json criado.");
    }

    private string EncontrarMelhorCod(string campoPdf, List<string> codsXml)
    {
        string normalizadoPdf = Normalizar(campoPdf);

        return codsXml
            .OrderBy(cod => Distancia(normalizadoPdf, Normalizar(cod)))
            .FirstOrDefault() ?? "";
    }

    private string Normalizar(string texto)
    {
        return texto
            .ToUpper()
            .Replace("Á", "A")
            .Replace("À", "A")
            .Replace("Ã", "A")
            .Replace("Â", "A")
            .Replace("É", "E")
            .Replace("Ê", "E")
            .Replace("Í", "I")
            .Replace("Ó", "O")
            .Replace("Õ", "O")
            .Replace("Ô", "O")
            .Replace("Ú", "U")
            .Replace("Ç", "C")
            .Replace(" ", "_")
            .Replace("(", "")
            .Replace(")", "")
            .Replace("-", "_")
            .Replace("‐", "_");
    }

    private int Distancia(string a, string b)
    {
        int[,] dp = new int[a.Length + 1, b.Length + 1];

        for (int i = 0; i <= a.Length; i++)
            dp[i, 0] = i;

        for (int j = 0; j <= b.Length; j++)
            dp[0, j] = j;

        for (int i = 1; i <= a.Length; i++)
        {
            for (int j = 1; j <= b.Length; j++)
            {
                int custo = a[i - 1] == b[j - 1] ? 0 : 1;

                dp[i, j] = Math.Min(
                    Math.Min(dp[i - 1, j] + 1, dp[i, j - 1] + 1),
                    dp[i - 1, j - 1] + custo
                );
            }
        }

        return dp[a.Length, b.Length];
    }
}