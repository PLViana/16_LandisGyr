using System.Runtime.InteropServices;
using ChecklistValidator.services;

namespace ChecklistValidator;

public static class LibExports
{
    // Esse atributo faz a função ficar visível para QUALQUER outra linguagem do PC
    [UnmanagedCallersOnly(EntryPoint = "ValidarXmlMedidor")]
    public static int ValidarXmlMedidor(IntPtr ponteiroCaminhoPadrao, IntPtr ponteiroCaminhoCliente, IntPtr ponteiroCaminhoSaida)
    {
        try
        {
            // Converte os ponteiros de texto nativos para string do C#
            string caminhoPadrao = Marshal.PtrToStringAnsi(ponteiroCaminhoPadrao) ?? "";
            string caminhoCliente = Marshal.PtrToStringAnsi(ponteiroCaminhoCliente) ?? "";
            string caminhoSaida = Marshal.PtrToStringAnsi(ponteiroCaminhoSaida) ?? "";

            var resultado = ChecklistValidato.Validar(caminhoPadrao, caminhoCliente);

            // Salva o JSON na máquina para o sistema deles ler
            System.IO.File.WriteAllText(caminhoSaida, System.Text.Json.JsonSerializer.Serialize(resultado));

            // Retorna 0 se passou, ou a quantidade de erros encontrados
            return resultado.Count;
        }
        catch
        {
            return -1; // Retorna -1 se deu algum erro crítico (ex: arquivo corrompido)
        }
    }
}