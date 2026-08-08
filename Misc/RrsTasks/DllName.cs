

using System.ComponentModel;
using Nuke.Common.Tooling;

[TypeConverter(typeof(Enumeration.TypeConverter<DllName>))]
public class DllName : Enumeration
{
    public static readonly DllName D3D9 = new() { Value = nameof(D3D9) };
    public static readonly DllName D3D10 = new() { Value = nameof(D3D10) };
    public static readonly DllName D3D11 = new() { Value = nameof(D3D11) };
    public static readonly DllName DXGI = new() { Value = nameof(DXGI) };
    public static readonly DllName OpenGL = new() { Value = nameof(OpenGL) };

    public string GetDllName(Architecture arch) => this == OpenGL
        ? this.Value.ToLower() + arch.Bits + ".dll"
        : this.Value.ToLower() + ".dll"
    ;
}
