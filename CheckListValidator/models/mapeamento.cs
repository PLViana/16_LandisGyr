namespace ChecklistValidator.models;

public class Mapeamento
{ 
    public string CampoPdf { get; set; } = "";

    public string CodXml { get; set; } = "";

    public Dictionary<string, string> Valores { get; set; } = new();
}