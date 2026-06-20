using ChecklistValidator.models;
using System.Xml.Linq;

namespace ChecklistValidator.services;

public static class ChecklistValidato
{
    public static List<Diferenca> Validar(
        string caminhoPadrao,
        string caminhoCliente)
    {
        var xmlPadrao = XDocument.Load(caminhoPadrao);

        var xmlCliente = XDocument.Load(caminhoCliente);

        XmlComparer comparer = new();

        return comparer.Comparar(
            xmlPadrao,
            xmlCliente
        );
    }
}