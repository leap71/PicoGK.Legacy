using System.Runtime.InteropServices;
using PicoGK;

if (Config.strPicoGKLib != "picogk")
    throw new InvalidOperationException($"Expected unversioned import 'picogk', found '{Config.strPicoGKLib}'.");

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
