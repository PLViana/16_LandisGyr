using System.Xml.Linq;
using UglyToad.PdfPig;
using System.Text.Json;
using ChecklistValidator.models;

namespace ChecklistValidator.services;

public class PdfConverter
{   
    public XDocument Converter(string caminhoPdf, string caminhoCliente)
    {
        var parametrosPdf = LerParametros(caminhoPdf);

        var xmlEsperado = new XDocument(new XElement("ROOT"));

        var json = File.ReadAllText("mapeamento.json");
        var mapa = JsonSerializer.Deserialize<List<Mapeamento>>(json)!;

        foreach (var item in mapa)
        {
            string nomePdf = item.CampoPdf;
            string codXml = item.CodXml;

            if (!parametrosPdf.ContainsKey(nomePdf))
            {
                xmlEsperado.Root!.Add(
                    new XElement("VAR",
                        new XAttribute("COD", codXml),
                        new XAttribute("VL", ""),
                        new XAttribute("IX", "")
                    )
                );

                continue;
            }

            string valorPdf = parametrosPdf[nomePdf];

            string ix = "";

            if (item.Valores != null && item.Valores.TryGetValue(valorPdf, out var ixConvertido))
            {
                ix = ixConvertido;
            }

            xmlEsperado.Root!.Add(
                new XElement("VAR",
                    new XAttribute("COD", codXml),
                    new XAttribute("VL", valorPdf),
                    new XAttribute("IX", ix)
                )
            );
        }

        return xmlEsperado;
    }


    
    public Dictionary<string, string> LerParametros(string caminhoPdf)
    {
        Dictionary<string, string> parametros = new();

        using (var document = PdfDocument.Open(caminhoPdf))
        {
            var page = document.GetPage(1);

            var words = page.GetWords().ToList();

            double toleranciaY = 3;

            var linhas = words
                .GroupBy(w => Math.Round(w.BoundingBox.Bottom / toleranciaY))
                .OrderByDescending(g => g.Key)
                .Select(g => g.OrderBy(w => w.BoundingBox.Left).ToList());

            foreach (var linha in linhas)
            {
                string textoLinha = string.Join(" ", linha.Select(w => w.Text));

            if (!textoLinha.Contains(":"))
                continue;

            string[] partes = textoLinha.Split(':', 2);

            string chave = partes[0].Trim();
            string valor = partes[1].Trim();

            parametros[chave] = valor;

           /// Console.WriteLine($"{chave} => {valor}");
            }
        }

        return parametros;
    }
}