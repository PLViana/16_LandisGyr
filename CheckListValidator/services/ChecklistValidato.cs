using ChecklistValidator.models;
using System.Xml.Linq;

namespace ChecklistValidator.services;

public static class ChecklistValidato
{
   public static List<Diferenca> Validar(
    string caminhoPadrao,
    string caminhoCliente)
{
    XDocument xmlPadrao = CarregarArquivo(caminhoPadrao, caminhoCliente);
    XDocument xmlCliente = CarregarArquivo(caminhoCliente, caminhoCliente);

    XmlComparer comparer = new();

    return comparer.Comparar(xmlPadrao, xmlCliente);
}

private static XDocument CarregarArquivo(string caminhoArquivo, string caminhoXmlBase)
{
    string extensao = Path.GetExtension(caminhoArquivo).ToLower();

    switch (extensao)
    {
        case ".xml":
            return XDocument.Load(caminhoArquivo);

        case ".pdf":
            PdfConverter pdf = new();
            return pdf.Converter(caminhoArquivo, caminhoXmlBase);

        default:
            throw new Exception("Formato de arquivo não suportado.");
    }
}
}