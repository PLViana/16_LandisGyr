
using ChecklistValidator.services;
using System.Text.Json;

try
{
    PdfConverter pdf = new();

    var resultado = ChecklistValidato.Validar(
    
            "FolhaParametro.pdf",
             "padrao.xml"
        );


    if (resultado.Count == 0)
    {
        Console.WriteLine("PASS");
    }
    else
    {
        Console.WriteLine("FAIL");

        foreach (var item in resultado)
        {
            Console.WriteLine("--------------------------------");
            Console.WriteLine($"COD: {item.Cod}");
            Console.WriteLine($"Campo Divergente: {item.CampoDivergente}");
            Console.WriteLine($"Esperado: {item.Esperado}");
            Console.WriteLine($"Encontrado: {item.Encontrado}");
        }
    }

    var resultadoJson = new
{
    Status = resultado.Count == 0 ? "PASS" : "FAIL",
    QuantidadeErros = resultado.Count,
    Diferencas = resultado
};

        File.WriteAllText(
        "resultado.json",
        JsonSerializer.Serialize(
            resultadoJson,
            new JsonSerializerOptions
            {
                WriteIndented = true
            }
        )
    );
}
catch (Exception ex)
{
    Console.WriteLine(ex.Message);
}
