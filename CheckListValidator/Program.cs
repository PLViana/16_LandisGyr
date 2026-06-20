
using ChecklistValidator.services;
using System.Text.Json;

try
{
    var resultado = ChecklistValidato.Validar(
        "padrao.xml",
        "cliente.xml"
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

    File.WriteAllText(
        "resultado.json",
        JsonSerializer.Serialize(
            resultado,
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