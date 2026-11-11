using System.Runtime.InteropServices;
using PicoGK;

string strExpectedNativeName = Environment.GetEnvironmentVariable("PICOGK_NATIVE_BASENAME")
    ?? throw new InvalidOperationException("PICOGK_NATIVE_BASENAME is not defined.");

if (Config.strPicoGKLib != strExpectedNativeName)
    throw new InvalidOperationException($"Expected native import '{strExpectedNativeName}', found '{Config.strPicoGKLib}'.");

Console.WriteLine($"PicoGK package: {typeof(Config).Assembly.FullName}");
Console.WriteLine($"Process architecture: {RuntimeInformation.ProcessArchitecture}");

nint hLibrary = NativeLibrary.Load(Config.strPicoGKLib, typeof(Config).Assembly, null);
try
{
    Console.WriteLine("Native PicoGK runtime loaded successfully.");
}
finally
{
    NativeLibrary.Free(hLibrary);
}
