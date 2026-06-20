using System.Xml.Linq;
using ChecklistValidator.models;

namespace ChecklistValidator.services;

public class XmlComparer
{
    public List<Diferenca> Comparar(
        XDocument padrao,
        XDocument cliente)
    {
        List<Diferenca> diferencas = new();

        var clienteDict = cliente.Root!
            .Elements("VAR")
            .ToDictionary(
                x => x.Attribute("COD")?.Value ?? "",
                x => x
            );

        foreach (var itemPadrao in padrao.Root!.Elements("VAR"))
        {
            string cod =
                itemPadrao.Attribute("COD")?.Value ?? "";

            if (!clienteDict.ContainsKey(cod))
            {
                diferencas.Add(new Diferenca
                {
                    Cod = cod,
                    CampoDivergente = "PARAMETRO_AUSENTE",
                    Esperado = "EXISTE",
                    Encontrado = "NAO ENCONTRADO"
                });

                continue;
            }

            var itemCliente = clienteDict[cod];

            string vlPadrao =
                itemPadrao.Attribute("VL")?.Value ?? "";

            string vlCliente =
                itemCliente.Attribute("VL")?.Value ?? "";

            if (vlPadrao != vlCliente)
            {
                diferencas.Add(new Diferenca
                {
                    Cod = cod,
                    CampoDivergente = "VL",
                    Esperado = vlPadrao,
                    Encontrado = vlCliente
                });
            }

            string ixPadrao =
                itemPadrao.Attribute("IX")?.Value ?? "";

            string ixCliente =
                itemCliente.Attribute("IX")?.Value ?? "";

            if (ixPadrao != ixCliente)
            {
                diferencas.Add(new Diferenca
                {
                    Cod = cod,
                    CampoDivergente = "IX",
                    Esperado = ixPadrao,
                    Encontrado = ixCliente
                });
            }
        }

        var padraoCods = padrao.Root!
            .Elements("VAR")
            .Select(x => x.Attribute("COD")?.Value ?? "")
            .ToHashSet();

        foreach (var itemCliente in cliente.Root!.Elements("VAR"))
        {
            string cod =
                itemCliente.Attribute("COD")?.Value ?? "";

            if (!padraoCods.Contains(cod))
            {
                diferencas.Add(new Diferenca
                {
                    Cod = cod,
                    CampoDivergente = "PARAMETRO_EXTRA",
                    Esperado = "NAO EXISTE",
                    Encontrado = "EXISTE"
                });
            }
        }

        return diferencas;
    }
}