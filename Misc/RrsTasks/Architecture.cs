

using System.ComponentModel;
using Nuke.Common.Tooling;

[TypeConverter(typeof(Enumeration.TypeConverter<Architecture>))]
public class Architecture : Enumeration
{
    public static readonly Architecture X64 = new() { Value = nameof(X64), Bits = 64 };
    public static readonly Architecture X86 = new() { Value = nameof(X86), Bits = 32 };

    public int Bits;
}
